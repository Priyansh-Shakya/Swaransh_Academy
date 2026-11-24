import json
import logging
import secrets
import uuid
from dataclasses import dataclass
from datetime import date

from fastapi import HTTPException

from app.core import fcm_service
from app.features.payment import ledger
from . import billing, client, repository as repo
from .config import settings
from .models import (
    CheckoutOptions, FeeStatusResponse, OrderStatusResponse, Prefill,
    SimpleCreateOrderRequest, SimpleCreateOrderResponse,
    SimpleVerifyPaymentRequest, SimpleVerifyPaymentResponse,
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


def _send_email_receipt_noop(res: ledger.PaymentResult) -> None:
    """No-op email receipt hook (Brevo HTTP API deferred for future task)."""
    pass


async def _dispatch_settlement_notifications(db, res: ledger.PaymentResult) -> None:
    """Dispatches FCM push notifications safely after transaction commit."""
    try:
        c_lbl = billing.cycle_label(res.cycle_start, res.cycle_end) if res.cycle_start and res.cycle_end else ""

        # 1. Student Push
        user_row = await db.fetchrow(
            """
            select u.fcm_token
            from users u
            join students s on s.user_id = u.user_id
            where s.id = $1 and u.fcm_token is not null
            """,
            res.student_id,
        )
        if user_row and user_row["fcm_token"]:
            if res.completed:
                msg = f"Payment of ₹{res.amount} received for {c_lbl}. Fees paid till {res.fee_paid_till_after:%d %b %Y}."
            else:
                msg = f"₹{res.amount} received for {c_lbl}. ₹{res.balance_after} remaining."
            fcm_service.send_notification(
                user_row["fcm_token"],
                "Payment Received",
                msg,
                data={"type": "payment_success", "student_id": str(res.student_id)},
            )

        # 2. Admin Push
        if res.completed:
            admin_msg = f"{res.student_name} paid ₹{res.amount} ({res.mode}), Full cycle paid."
        else:
            admin_msg = f"{res.student_name} paid ₹{res.amount} ({res.mode}), Part payment, ₹{res.balance_after} due."
        await fcm_service.send_to_admins(
            db,
            "Payment Settlement",
            admin_msg,
            data={"type": "payment_success", "student_id": str(res.student_id)},
        )

        # 3. Overpayment Push
        if res.overpaid_by > 0:
            over_msg = f"Overpayment: {res.student_name} paid ₹{res.amount}; cycle {c_lbl} was already fully paid. Review or refund."
            await fcm_service.send_to_admins(
                db,
                "Overpayment Alert",
                over_msg,
                data={"type": "payment_overpaid", "student_id": str(res.student_id)},
            )

        _send_email_receipt_noop(res)
    except Exception as exc:
        log.error("Failed to dispatch settlement notifications: %s", exc)


# ------------------------------------------------------------------ 1. start
async def start_payment(db, user: dict, body: StartPaymentRequest) -> CheckoutOptions:
    async with db.transaction():
        await repo.lock_student_orders(db, body.student_id)
        student = await _own_student(db, body.student_id, user)

        fee_rupees, fee_type = _fee_details(student)
        today = billing.today_ist()
        c_start, c_end = billing.current_cycle(student["fee_paid_till"], student["date_of_joining"], fee_type)
        c_paid = await repo.get_cycle_paid(db, student["id"], c_start)
        c_balance = max(0, fee_rupees - c_paid)

        can_pay = (student["fee_paid_till"] is None or student["fee_paid_till"] < today) and c_balance > 0
        if not can_pay:
            reason = (
                f"Fees are already paid until {student['fee_paid_till']:%d %b %Y}"
                if student["fee_paid_till"] else "Fees are paid up to date"
            )
            raise HTTPException(409, reason)

        approved_part = student.get("partial_payment_amount")
        part_available = (
            bool(student.get("allow_partial_payment"))
            and approved_part is not None
            and approved_part < c_balance
        )

        if body.amount is not None:
            if body.amount > c_balance:
                raise HTTPException(422, f"Amount cannot exceed the balance of ₹{c_balance}")
            if body.amount < c_balance:
                if not part_available:
                    raise HTTPException(422, "Part payment is not available for this student")
                if body.amount != approved_part:
                    raise HTTPException(422, f"Part payment must be exactly ₹{approved_part} as approved by the academy")
            amount_rupees = body.amount
        else:
            amount_rupees = c_balance

        amount_paise = amount_rupees * 100
        c_lbl = billing.cycle_label(c_start, c_end)
        is_partial = amount_rupees < c_balance
        desc = f"Part payment {c_lbl}" if is_partial else f"{fee_type.replace('_', ' ').title()} fees {c_lbl}"
        if len(desc) > 35:
            desc = f"Fees {c_lbl}"

        order_id = await repo.find_reusable_order(db, student["id"], amount_paise, c_start)
        if order_id is None:
            try:
                order = await client.create_order(
                    amount_paise,
                    receipt=f"stu{student['id']}-{secrets.token_hex(4)}",
                    notes={"student_id": str(student["id"]), "cycle_start": str(c_start)},
                )
            except client.RazorpayError as exc:
                log.error("Razorpay order creation failed: %s", exc)
                raise HTTPException(502, "Payment gateway unavailable, please try again")
            order_id = order["id"]
            await repo.insert_order(db, student["id"], order_id, amount_paise, c_start, c_end, fee_rupees, cycles=1)

    return CheckoutOptions(
        key_id=settings.key_id,
        order_id=order_id,
        amount=amount_paise,
        name=settings.academy_name,
        description=desc,
        prefill=Prefill(
            name=student["name"], contact=student["contact"], email=student["email"]
        ),
        covers_from=c_start,
        covers_till=c_end,
        cycle_label=c_lbl,
        is_partial=is_partial,
    )


# ------------------------------------------------------------------ settlement (shared)
async def settle_order(
    db, razorpay_order_id: str, razorpay_payment_id: str,
    paid_paise: int, method: str | None,
) -> SettleOutcome:
    """Idempotent. Lock order, apply payment, mark order paid in ONE transaction."""
    res = None
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

        cycle_tuple = None
        if order["cycle_start"] and order["cycle_end"] and order["cycle_fee"]:
            cycle_tuple = (order["cycle_start"], order["cycle_end"], order["cycle_fee"])

        res = await ledger.apply_payment(
            db=db,
            student_id=order["student_id"],
            amount_rupees=paid_paise // 100,
            mode=_MODE_BY_METHOD.get(method or "", "other"),
            txn_ref=razorpay_payment_id,
            cycle=cycle_tuple,
            source="online",
        )
        await repo.mark_order_paid(db, order["id"], razorpay_payment_id, res.payment_id)
        # Clear online partial payment approval after settlement
        await repo.consume_partial_payment_approval(db, order["student_id"])

    if res is not None:
        await _dispatch_settlement_notifications(db, res)

    return SettleOutcome("settled", payment_id=res.payment_id, fee_paid_till=res.fee_paid_till_after)


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
    if event_type == "payment.failed":
        payload_entity = (event.get("payload", {}).get("payment", {}) or {}).get("entity", {})
        order_id = payload_entity.get("order_id")
        payment_id = payload_entity.get("id")
        error_desc = payload_entity.get("error_description") or payload_entity.get("error_reason") or "Payment failed at bank"
        if not order_id or not payment_id:
            return

        order = await repo.get_order(db, order_id)
        if not order:
            return

        recorded = await repo.record_failed_order(db, order["id"], payment_id, error_desc)
        if recorded:
            # Send student and admin failure pushes
            try:
                user_row = await db.fetchrow(
                    """
                    select u.fcm_token
                    from users u
                    join students s on s.user_id = u.user_id
                    where s.id = $1 and u.fcm_token is not null
                    """,
                    order["student_id"],
                )
                student_name = await db.fetchval("select name from students where id = $1", order["student_id"])
                if user_row and user_row["fcm_token"]:
                    fcm_service.send_notification(
                        user_row["fcm_token"],
                        "Payment Failed",
                        f"Payment failed: {error_desc}. If money was debited, your bank usually reverses it automatically.",
                        data={"type": "payment_failed", "student_id": str(order["student_id"])},
                    )
                await fcm_service.send_to_admins(
                    db,
                    "Payment Failure Alert",
                    f"Payment failed for {student_name or 'student'}: {error_desc}.",
                    data={"type": "payment_failed", "student_id": str(order["student_id"])},
                )
            except Exception as exc:
                log.error("Failed to dispatch payment failure notifications: %s", exc)
        return

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
        last_error=order["last_error"],
    )


async def get_fee_status(db, user: dict, student_id: int, is_admin_user: bool = False) -> FeeStatusResponse:
    if is_admin_user:
        student = await repo.get_student_by_id(db, student_id)
        if not student:
            raise HTTPException(404, "Student not found")
    else:
        student = await _own_student(db, student_id, user)

    fee_rupees, fee_type = _fee_details(student)
    today = billing.today_ist()
    c_start, c_end = billing.current_cycle(student["fee_paid_till"], student["date_of_joining"], fee_type)
    c_lbl = billing.cycle_label(c_start, c_end)
    c_paid = await repo.get_cycle_paid(db, student["id"], c_start)
    c_balance = max(0, fee_rupees - c_paid)

    can_pay = (student["fee_paid_till"] is None or student["fee_paid_till"] < today) and c_balance > 0
    cannot_pay_reason = None
    if not can_pay:
        if c_balance <= 0:
            cannot_pay_reason = f"Fees for {c_lbl} are fully paid until {student['fee_paid_till']:%d %b %Y}" if student['fee_paid_till'] else "Fees fully paid"
        elif student["fee_paid_till"] and student["fee_paid_till"] >= today:
            cannot_pay_reason = f"Fees are already paid until {student['fee_paid_till']:%d %b %Y}"
        else:
            cannot_pay_reason = "Fees are paid up to date"

    next_due = billing.cycle_start(student["fee_paid_till"], student["date_of_joining"])

    has_unlinked = await db.fetchval(
        """
        select exists (
            select 1 from payment
            where student_id = $1
              and payment_category in ('fee', 'admission')
              and cycle_start is null
              and coalesce(isactive, true)
              and coalesce(status::text, 'active') = 'active'
        )
        """,
        student["id"],
    )

    approved_part = student.get("partial_payment_amount")
    part_available = (
        bool(student.get("allow_partial_payment"))
        and approved_part is not null
        and approved_part < c_balance
    )

    return FeeStatusResponse(
        student_id=student["id"],
        fee_type=fee_type,
        fee_amount=fee_rupees,
        fee_paid_till=student["fee_paid_till"],
        next_due_date=next_due,
        is_due=can_pay,
        can_pay=can_pay,
        cannot_pay_reason=cannot_pay_reason,
        cycle_start=c_start,
        cycle_end=c_end,
        cycle_label=c_lbl,
        cycle_fee=fee_rupees,
        cycle_paid=c_paid,
        cycle_balance=c_balance,
        allow_partial_payment=bool(student.get("allow_partial_payment")),
        partial_payment_amount=approved_part,
        part_payment_available=part_available,
        has_unlinked_payments=bool(has_unlinked),
    )


async def toggle_partial_payment(
    db, student_id: int, allow: bool, amount: int | None = None
) -> FeeStatusResponse:
    student = await repo.get_student_by_id(db, student_id)
    if not student:
        raise HTTPException(404, "Student not found")

    fee_rupees, fee_type = _fee_details(student)
    c_start, _ = billing.current_cycle(student["fee_paid_till"], student["date_of_joining"], fee_type)
    c_paid = await repo.get_cycle_paid(db, student["id"], c_start)
    c_balance = max(0, fee_rupees - c_paid)

    if allow:
        if amount is None or amount < 1 or amount >= c_balance:
            raise HTTPException(
                422,
                f"Approved partial payment amount must be between ₹1 and ₹{c_balance - 1} for this cycle (Balance is ₹{c_balance})",
            )
    else:
        allow = False
        amount = None

    await repo.update_allow_partial_payment(db, student_id, allow, amount)
    return await get_fee_status(db, {}, student_id, is_admin_user=True)


# ------------------------------------------------------------------ 5. standard Razorpay endpoints
async def create_simple_order(body: SimpleCreateOrderRequest) -> SimpleCreateOrderResponse:
    if body.amount < 100:
        raise HTTPException(400, "Amount must be at least 100 paise")
    try:
        receipt = body.receipt or f"rcpt_{secrets.token_hex(4)}"
        order = await client.create_order(
            amount_paise=body.amount, receipt=receipt, notes=body.notes or {}
        )
    except client.RazorpayError as exc:
        log.error("Razorpay order creation failed: %s", exc)
        raise HTTPException(500, f"Order creation failed: {exc}")

    return SimpleCreateOrderResponse(
        order_id=order["id"], amount=order["amount"], currency=order["currency"]
    )


async def verify_simple_payment(body: SimpleVerifyPaymentRequest) -> SimpleVerifyPaymentResponse:
    order_id = body.resolved_order_id
    payment_id = body.resolved_payment_id
    signature = body.resolved_signature

    if not order_id or not payment_id or not signature:
        raise HTTPException(400, "Missing required fields: order_id, payment_id, and signature are required")

    is_valid = client.verify_checkout_signature(order_id, payment_id, signature)
    if not is_valid:
        raise HTTPException(400, "Invalid payment signature")

    return SimpleVerifyPaymentResponse(
        status="success", message="Payment signature verified successfully"
    )
