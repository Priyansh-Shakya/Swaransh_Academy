from dataclasses import dataclass
from datetime import date, datetime
import logging

from fastapi import HTTPException

from app.features.payment.razorpay import billing

log = logging.getLogger(__name__)


@dataclass
class PaymentResult:
    payment_id: int
    student_id: int
    student_name: str
    amount: int
    cycle_start: date | None
    cycle_end: date | None
    cycle_fee: int | None
    cycle_paid_after: int
    balance_after: int
    completed: bool
    overpaid_by: int
    fee_paid_till_after: date | None
    payment_type: str
    category: str
    mode: str
    source: str  # 'online' | 'manual'


async def apply_payment(
    db,
    student_id: int,
    amount_rupees: int,
    payment_type: str | None = None,
    category: str = "fee",
    mode: str = "other",
    txn_ref: str | None = None,
    paid_on: datetime | date | None = None,
    cycle: tuple[date, date, int] | None = None,  # (start, end, fee)
    source: str = "manual",
    record_only: bool = False,
) -> PaymentResult:
    """Core transaction-scoped ledger logic for applying a payment to a student.

    MUST run inside an open transaction. Locks the student row FOR UPDATE.
    """
    if amount_rupees <= 0:
        raise HTTPException(422, "Payment amount must be greater than zero")

    student = await db.fetchrow(
        """
        select id, name, fees, fee_type::text as fee_type, fee_paid_till,
               date_of_joining, status::text as status
        from students
        where id = $1
        for update
        """,
        student_id,
    )
    if not student:
        raise HTTPException(404, "Student not found")

    # Record-only or category 'other' entries: plain ledger insert, no cycle calculations or date changes.
    if category == "other" or record_only:
        p_type = payment_type or "monthly"
        p_id = await db.fetchval(
            """
            insert into payment (student_id, payment_type, amount, mode, txn_ref, payment_category, paid_on, status, isactive)
            values ($1, $2::payment_type, $3, $4::payment_mode, $5, $6::payment_cat, coalesce($7, now()), 'active', true)
            returning id
            """,
            student_id, p_type, amount_rupees, mode, txn_ref, category, paid_on,
        )
        return PaymentResult(
            payment_id=p_id,
            student_id=student_id,
            student_name=student["name"],
            amount=amount_rupees,
            cycle_start=None,
            cycle_end=None,
            cycle_fee=None,
            cycle_paid_after=amount_rupees,
            balance_after=0,
            completed=False,
            overpaid_by=0,
            fee_paid_till_after=student["fee_paid_till"],
            payment_type=p_type,
            category=category,
            mode=mode,
            source=source,
        )

    # Resolve cycle (either from snapshot on order or current cycle from student details)
    if cycle is not None:
        c_start, c_end, c_fee = cycle
    else:
        if not student["fees"] or not student["fee_type"]:
            raise HTTPException(422, "Student has no fees or fee_type set")
        c_fee = billing.fee_to_rupees(student["fees"])
        f_type = billing.normalize_fee_type(student["fee_type"])
        c_start, c_end = billing.current_cycle(student["fee_paid_till"], student["date_of_joining"], f_type)

    # Resolve payment_type and category if first payment
    has_active = await db.fetchval(
        """
        select exists (
            select 1 from payment
            where student_id = $1
              and coalesce(isactive, true)
              and coalesce(status::text, 'active') = 'active'
        )
        """,
        student_id,
    )
    p_type = payment_type or ("admission" if not has_active else billing.normalize_fee_type(student["fee_type"]))
    p_cat = "admission" if not has_active else category

    p_id = await db.fetchval(
        """
        insert into payment (
            student_id, payment_type, amount, mode, txn_ref, payment_category,
            paid_on, cycle_start, cycle_end, cycle_fee, status, isactive
        )
        values ($1, $2::payment_type, $3, $4::payment_mode, $5, $6::payment_cat, coalesce($7, now()), $8, $9, $10, 'active', true)
        returning id
        """,
        student_id, p_type, amount_rupees, mode, txn_ref, p_cat, paid_on, c_start, c_end, c_fee,
    )

    cycle_paid_after = await db.fetchval(
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
    balance_after = max(0, c_fee - cycle_paid_after)
    completed = cycle_paid_after >= c_fee
    overpaid_by = max(0, cycle_paid_after - c_fee)

    new_fee_paid_till = student["fee_paid_till"]
    if completed:
        if student["fee_paid_till"] is None or c_end > student["fee_paid_till"]:
            new_fee_paid_till = c_end

        if student["status"] == "pending_payment":
            await db.execute(
                """
                update students
                set fee_paid_till = greatest(coalesce(fee_paid_till, '1970-01-01'::date), $2::date),
                    allow_partial_payment = false,
                    status = 'active',
                    updated_at = now()
                where id = $1
                """,
                student_id, c_end,
            )
        else:
            await db.execute(
                """
                update students
                set fee_paid_till = greatest(coalesce(fee_paid_till, '1970-01-01'::date), $2::date),
                    allow_partial_payment = false,
                    updated_at = now()
                where id = $1
                """,
                student_id, c_end,
            )

    return PaymentResult(
        payment_id=p_id,
        student_id=student_id,
        student_name=student["name"],
        amount=amount_rupees,
        cycle_start=c_start,
        cycle_end=c_end,
        cycle_fee=c_fee,
        cycle_paid_after=cycle_paid_after,
        balance_after=balance_after,
        completed=completed,
        overpaid_by=overpaid_by,
        fee_paid_till_after=new_fee_paid_till,
        payment_type=p_type,
        category=p_cat,
        mode=mode,
        source=source,
    )
