"""Service for Payment operations"""

from datetime import datetime
import logging
from typing import List

from fastapi import HTTPException

from app.core import fcm_service
from app.core.helper import convert_enums_to_values
from app.features.payment import ledger, repository
from app.features.payment.model import Payment, PaymentCreate
from app.features.payment.razorpay import billing

log = logging.getLogger(__name__)


async def create_payment(
    student_id: int, payment_create: PaymentCreate, db
) -> Payment:
    """Record a new manual payment."""
    data = payment_create.model_dump(mode="python")
    data = convert_enums_to_values(data)

    category = data.get("payment_category", "fee")
    record_only = data.get("record_only", False)
    amount = int(data.get("amount") or 0)

    async with db.transaction():
        student = await db.fetchrow(
            """
            select id, fees, fee_type::text as fee_type, fee_paid_till, date_of_joining
            from students where id = $1 for update
            """,
            student_id,
        )
        if not student:
            raise HTTPException(404, "Student not found")

        # Validate amount against current cycle balance for fee/admission non-record-only payments
        if category in ("fee", "admission") and not record_only:
            if not student["fees"] or not student["fee_type"]:
                raise HTTPException(422, "Student has no fees or fee_type set")
            f_rupees = billing.fee_to_rupees(student["fees"])
            f_type = billing.normalize_fee_type(student["fee_type"])
            c_start, _ = billing.current_cycle(
                student["fee_paid_till"], student["date_of_joining"], f_type
            )
            c_paid = await db.fetchval(
                """
                select coalesce(sum(amount), 0)
                from payment
                where student_id = $1
                  and cycle_start = $2
                  and coalesce(isactive, true)
                  and coalesce(status::text, 'active') = 'active'
                """,
                student_id, c_start,
            )
            c_balance = max(0, f_rupees - c_paid)
            if amount > c_balance:
                raise HTTPException(
                    422,
                    f"Amount ₹{amount} exceeds the balance of ₹{c_balance} for this cycle. Record it as two entries.",
                )

        res = await ledger.apply_payment(
            db=db,
            student_id=student_id,
            amount_rupees=amount,
            payment_type=data.get("payment_type"),
            category=category,
            mode=data.get("mode", "cash"),
            txn_ref=data.get("txn_ref"),
            paid_on=data.get("paid_on"),
            source="manual",
            record_only=record_only,
        )

        # Send push notification if paid_on is omitted or within last 2 days
        paid_on_dt = data.get("paid_on")
        is_recent = True
        if paid_on_dt is not None:
            today = billing.today_ist()
            p_date = paid_on_dt.date() if isinstance(paid_on_dt, datetime) else paid_on_dt
            is_recent = (today - p_date).days <= 2

        if is_recent and res.cycle_start and res.cycle_end:
            user_row = await db.fetchrow(
                """
                select u.fcm_token
                from users u
                join students s on s.user_id = u.user_id
                where s.id = $1 and u.fcm_token is not null
                """,
                student_id,
            )
            if user_row and user_row["fcm_token"]:
                c_lbl = billing.cycle_label(res.cycle_start, res.cycle_end)
                if res.completed:
                    msg = f"Payment of ₹{res.amount} received for {c_lbl}. Fees paid till {res.fee_paid_till_after:%d %b %Y}."
                else:
                    msg = f"₹{res.amount} received for {c_lbl}. ₹{res.balance_after} remaining."
                fcm_service.send_notification(
                    user_row["fcm_token"],
                    "Payment Received",
                    msg,
                    data={"type": "payment_success", "student_id": str(student_id)},
                )

        row = await db.fetchrow("select * from payment where id = $1", res.payment_id)
        p_dict = dict(row)
        if p_dict.get("cycle_start") and p_dict.get("cycle_end"):
            p_dict["cycle_label"] = billing.cycle_label(
                p_dict["cycle_start"], p_dict["cycle_end"]
            )
        return Payment(**p_dict)


async def get_payment(payment_id: int, db) -> Payment:
    """Get payment by ID"""
    row = await db.fetchrow(repository.get_payment_by_id_query, payment_id)
    if not row:
        raise HTTPException(404, f"Payment {payment_id} not found")
    p_dict = dict(row)
    if p_dict.get("cycle_start") and p_dict.get("cycle_end"):
        p_dict["cycle_label"] = billing.cycle_label(
            p_dict["cycle_start"], p_dict["cycle_end"]
        )
    return Payment(**p_dict)


async def correct_payment(
    student_id: int,
    payment_id: int,
    payment_create: PaymentCreate,
    db,
) -> Payment:
    """Correct a payment using the supersede pattern. Inherits cycle columns, does not touch fee_paid_till."""
    data = payment_create.model_dump(mode="python")
    data = convert_enums_to_values(data)

    async with db.transaction():
        old_row = await db.fetchrow(
            "select * from payment where id = $1 and student_id = $2 for update",
            payment_id, student_id,
        )
        if not old_row:
            raise HTTPException(404, "Payment not found for this student")

        new_row = await db.fetchrow(
            """
            insert into payment (
                student_id, payment_type, amount, mode, txn_ref, paid_on, status,
                payment_category, cycle_start, cycle_end, cycle_fee, isactive
            )
            values ($1, $2::payment_type, $3, $4::payment_mode, $5, coalesce($6, now()), 'active', $7::payment_cat, $8, $9, $10, true)
            returning *
            """,
            student_id,
            data.get("payment_type") or old_row["payment_type"],
            int(data.get("amount") or 0),
            data.get("mode") or old_row["mode"],
            data.get("txn_ref") or old_row["txn_ref"],
            data.get("paid_on"),
            data.get("payment_category") or old_row["payment_category"],
            old_row["cycle_start"],
            old_row["cycle_end"],
            old_row["cycle_fee"],
        )
        new_id = new_row["id"]
        await db.execute(repository.supersede_payment_query, new_id, payment_id)

        p_dict = dict(new_row)
        if p_dict.get("cycle_start") and p_dict.get("cycle_end"):
            p_dict["cycle_label"] = billing.cycle_label(
                p_dict["cycle_start"], p_dict["cycle_end"]
            )
        return Payment(**p_dict)


async def delete_payment(student_id: int, payment_id: int, db) -> None:
    """Hard delete a payment (reserved for genuine duplicates). Verifies student_id."""
    async with db.transaction():
        row = await db.fetchrow(
            "select id from payment where id = $1 and student_id = $2",
            payment_id, student_id,
        )
        if not row:
            raise HTTPException(404, "Payment not found for this student")
        await db.execute("delete from payment where id = $1", payment_id)


async def get_payment_history(student_id: int, db) -> List[Payment]:
    """Get payment history for a student"""
    rows = await db.fetch(repository.get_payments_by_student_query, student_id)
    result = []
    for row in rows:
        p_dict = dict(row)
        if p_dict.get("cycle_start") and p_dict.get("cycle_end"):
            p_dict["cycle_label"] = billing.cycle_label(
                p_dict["cycle_start"], p_dict["cycle_end"]
            )
        result.append(Payment(**p_dict))
    return result


async def get_all_payments(db) -> List[Payment]:
    """Get all payments (admin view)"""
    rows = await db.fetch(repository.get_all_payments_query)
    result = []
    for row in rows:
        p_dict = dict(row)
        if p_dict.get("cycle_start") and p_dict.get("cycle_end"):
            p_dict["cycle_label"] = billing.cycle_label(
                p_dict["cycle_start"], p_dict["cycle_end"]
            )
        result.append(Payment(**p_dict))
    return result
