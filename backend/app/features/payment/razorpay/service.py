import json
import logging
import secrets
import uuid
from dataclasses import dataclass
from datetime import date

from fastapi import HTTPException

from . import billing, client, repository as repo
from .config import settings
from .models import (
    CheckoutOptions, FeeStatusResponse, OrderStatusResponse, Prefill,
    StartPaymentRequest, VerifyPaymentRequest, VerifyPaymentResponse,
)

log = logging.getLogger(__name__)

# Razorpay "method" -> your payment_mode enum {cash, upi, card, bank_transfer, other}
_MODE_BY_METHOD = {"upi": "upi", "card": "card", "netbanking": "bank_transfer"}


@dataclass
class SettleOutcome:
    status: str  # settled | already_paid | unknown_order | amount_mismatch
    payment_id: int | None = None
    fee_paid_till: date | None = None


# ------------------------------------------------------------------ helpers
def _user_uuid(user: dict) -> uuid.UUID:
    try:
        return uuid.UUID(str(user["id"]))
    except (KeyError, ValueError):
        raise HTTPException(401, "Invalid user")


async def _own_student(db, student_id: int, user: dict):
    student = await repo.get_student_for_user(db, student_id, _user_uuid(user))
    if student is None:
        raise HTTPException(404, "Student not found")
    return student


def _fee_details(student) -> tuple[int, str]:
    try:
        return (
            billing.fee_to_rupees(student["fees"]),
            billing.normalize_fee_type(student["fee_type"]),
        )
    except ValueError as exc:
        raise HTTPException(422, str(exc))


# ------------------------------------------------------------------ 1. start
async def start_payment(db, user: dict, body: StartPaymentRequest) -> CheckoutOptions:
    async with db.transaction():
        await repo.lock_student_orders(db, body.student_id)
        student = await _own_student(db, body.student_id, user)

        fee_rupees, fee_type = _fee_details(student)
        amount_paise = fee_rupees * body.cycles * 100  # amount comes from OUR db

        covers_from, covers_till = billing.coverage(
            student["fee_paid_till"], student["date_of_joining"], fee_type, body.cycles
        )

        order_id = await repo.find_reusable_order(
            db, student["id"], amount_paise, body.cycles
        )
        if order_id is None:
            try:
                order = await client.create_order(
                    amount_paise,
                    receipt=f"stu{student['id']}-{secrets.token_hex(4)}",
                    notes={"student_id": str(student["id"]), "cycles": str(body.cycles)},
                )
            except client.RazorpayError as exc:
                log.error("Razorpay order creation failed: %s", exc)
                raise HTTPException(502, "Payment gateway unavailable, please try again")
            order_id = order["id"]
            await repo.insert_order(db, student["id"], order_id, amount_paise, body.cycles)

    return CheckoutOptions(
        key_id=settings.key_id,
        order_id=order_id,
        amount=amount_paise,
        name=settings.academy_name,
        description=(
            f"{fee_type.replace('_', ' ').title()} fees: "
            f"{covers_from:%d %b %Y} to {covers_till:%d %b %Y}"
        ),
        prefill=Prefill(
            name=student["name"], contact=student["contact"], email=student["email"]
        ),
        cycles=body.cycles,
        covers_from=covers_from,
        covers_till=covers_till,
    )


# ------------------------------------------------------------------ settlement (shared)
async def settle_order(
    db, razorpay_order_id: str, razorpay_payment_id: str,
    paid_paise: int, method: str | None,
) -> SettleOutcome:
    """Idempotent. The order row lock makes verify + webhook race-safe."""
    async with db.transaction():
        order = await repo.lock_order(db, razorpay_order_id)
        if order is None:
            return SettleOutcome("unknown_order")
        if order["status"] == "paid":
            return SettleOutcome("already_paid", order["payment_id"])
        if order["amount_paise"] != paid_paise:
            log.error(
                "Amount mismatch on %s: paid=%s expected=%s",
                razorpay_order_id, paid_paise, order["amount_paise"],
            )
            return SettleOutcome("amount_mismatch")

        student = await repo.lock_student(db, order["student_id"])
        fee_type = billing.normalize_fee_type(student["fee_type"])

        is_first = not await repo.has_active_payment(db, student["id"])
        payment_type = "admission" if is_first else fee_type
        category = "admission" if is_first else "fee"

        _, paid_till = billing.coverage(
            student["fee_paid_till"], student["date_of_joining"], fee_type, order["cycles"]
        )

        payment_id = await repo.insert_payment(
            db,
            student_id=student["id"],
            payment_type=payment_type,
            amount_rupees=order["amount_paise"] // 100,
            mode=_MODE_BY_METHOD.get(method or "", "other"),
            txn_ref=razorpay_payment_id,
            category=category,
        )
        await repo.advance_fee_paid_till(db, student["id"], paid_till)
        await repo.mark_order_paid(db, order["id"], razorpay_payment_id, payment_id)

    # TODO (optional): send a push via fcm_service here, AFTER the transaction commits.
    return SettleOutcome("settled", payment_id, paid_till)


# ------------------------------------------------------------------ 2. verify (from the app)
async def verify_payment(db, user: dict, body: VerifyPaymentRequest) -> VerifyPaymentResponse:
    order = await repo.get_order(db, body.razorpay_order_id)
    if order is None:
        raise HTTPException(404, "Order not found")
    student = await _own_student(db, order["student_id"], user)

    if not client.verify_checkout_signature(
        body.razorpay_order_id, body.razorpay_payment_id, body.razorpay_signature
    ):
        raise HTTPException(400, "Invalid payment signature")

    if order["status"] == "paid":
        return VerifyPaymentResponse(
            status="paid", payment_id=order["payment_id"],
            fee_paid_till=student["fee_paid_till"],
        )

    try:
        rz_payment = await client.fetch_payment(body.razorpay_payment_id)
    except client.RazorpayError as exc:
        log.error("fetch_payment failed: %s", exc)
        raise HTTPException(502, "Could not confirm payment yet, please check again shortly")

    if rz_payment.get("order_id") != body.razorpay_order_id:
        raise HTTPException(400, "Payment does not belong to this order")

    if rz_payment.get("status") != "captured":
        # Authorized but not captured yet: the webhook will settle it when captured.
        return VerifyPaymentResponse(status="pending")

    outcome = await settle_order(
        db, body.razorpay_order_id, body.razorpay_payment_id,
        rz_payment["amount"], rz_payment.get("method"),
    )
    if outcome.status in ("settled", "already_paid"):
        fresh = await _own_student(db, order["student_id"], user)
        return VerifyPaymentResponse(
            status="paid", payment_id=outcome.payment_id,
            fee_paid_till=fresh["fee_paid_till"],
        )
    raise HTTPException(409, "Payment could not be applied; contact the academy")


# ------------------------------------------------------------------ 3. webhook (source of truth)
async def handle_webhook(db, raw_body: bytes, signature: str | None) -> None:
    if not client.verify_webhook_signature(raw_body, signature):
        raise HTTPException(400, "Invalid webhook signature")

    try:
        event = json.loads(raw_body)
    except ValueError:
        raise HTTPException(400, "Malformed webhook body")

    event_type = event.get("event")
    if event_type not in ("payment.captured", "order.paid"):
        log.info("Ignoring webhook event %s", event_type)
        return

    entity = (event.get("payload", {}).get("payment", {}) or {}).get("entity", {})
    order_id = entity.get("order_id")
    if entity.get("status") != "captured" or not order_id:
        return

    outcome = await settle_order(
        db, order_id, entity["id"], entity["amount"], entity.get("method")
    )
    log.info("Webhook %s for order %s -> %s", event_type, order_id, outcome.status)
    # Return normally even for unknown_order / amount_mismatch so Razorpay stops retrying.
    # DB errors propagate as 500, which makes Razorpay retry later (desired).


# ------------------------------------------------------------------ 4. status endpoints
async def get_order_status(db, user: dict, razorpay_order_id: str) -> OrderStatusResponse:
    order = await repo.get_order(db, razorpay_order_id)
    if order is None:
        raise HTTPException(404, "Order not found")
    student = await _own_student(db, order["student_id"], user)
    return OrderStatusResponse(
        razorpay_order_id=razorpay_order_id,
        status=order["status"],
        fee_paid_till=student["fee_paid_till"],
    )


async def get_fee_status(db, user: dict, student_id: int) -> FeeStatusResponse:
    student = await _own_student(db, student_id, user)
    fee_rupees, fee_type = _fee_details(student)
    next_due = billing.cycle_start(student["fee_paid_till"], student["date_of_joining"])
    return FeeStatusResponse(
        student_id=student["id"],
        fee_type=fee_type,
        fee_amount=fee_rupees,
        fee_paid_till=student["fee_paid_till"],
        next_due_date=next_due,
        is_due=next_due <= billing.today_ist(),
    )
