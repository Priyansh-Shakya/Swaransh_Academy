"""Raw SQL for the online-payment flow. `db` is an asyncpg connection."""
import uuid
from datetime import date

_STUDENT_COLS = """
    id, name, contact, email, fees, fee_type::text as fee_type,
    fee_paid_till, date_of_joining, allow_partial_payment, partial_payment_amount
"""


async def lock_student_orders(db, student_id: int) -> None:
    """Serialise order creation per student (released at transaction end)."""
    await db.execute("select pg_advisory_xact_lock(1001, $1)", student_id)


async def get_student_by_id(db, student_id: int):
    return await db.fetchrow(
        f"select {_STUDENT_COLS} from students where id = $1",
        student_id,
    )


async def get_student_for_user(db, student_id: int, user_id: uuid.UUID):
    return await db.fetchrow(
        f"select {_STUDENT_COLS} from students where id = $1 and user_id = $2",
        student_id, user_id,
    )


async def lock_student(db, student_id: int):
    return await db.fetchrow(
        f"select {_STUDENT_COLS} from students where id = $1 for update",
        student_id,
    )


async def find_reusable_order(
    db, student_id: int, amount_paise: int, cycle_start: date
) -> str | None:
    return await db.fetchval(
        """
        select razorpay_order_id from payment_order
        where student_id = $1 and status = 'created'
          and amount_paise = $2 and cycle_start = $3
          and created_at > now() - interval '1 day'
        order by id desc limit 1
        """,
        student_id, amount_paise, cycle_start,
    )


async def insert_order(
    db,
    student_id: int,
    razorpay_order_id: str,
    amount_paise: int,
    cycle_start: date,
    cycle_end: date,
    cycle_fee: int,
    cycles: int = 1,
) -> None:
    await db.execute(
        """
        insert into payment_order (
            student_id, razorpay_order_id, amount_paise, cycles,
            cycle_start, cycle_end, cycle_fee
        )
        values ($1, $2, $3, $4, $5, $6, $7)
        """,
        student_id, razorpay_order_id, amount_paise, cycles, cycle_start, cycle_end, cycle_fee,
    )


async def get_order(db, razorpay_order_id: str):
    return await db.fetchrow(
        """
        select id, student_id, razorpay_order_id, amount_paise, cycles, status,
               payment_id, cycle_start, cycle_end, cycle_fee, last_error
        from payment_order where razorpay_order_id = $1
        """,
        razorpay_order_id,
    )


async def lock_order(db, razorpay_order_id: str):
    return await db.fetchrow(
        """
        select id, student_id, razorpay_order_id, amount_paise, cycles, status,
               payment_id, cycle_start, cycle_end, cycle_fee, last_error
        from payment_order where razorpay_order_id = $1 for update
        """,
        razorpay_order_id,
    )


async def record_failed_order(
    db, order_id: int, payment_id: str, error_desc: str
) -> bool:
    """Returns True if recorded, False if deduplicated."""
    res = await db.execute(
        """
        update payment_order
        set last_error = $2,
            last_error_at = now(),
            last_failed_payment_id = $3
        where id = $1 and coalesce(last_failed_payment_id, '') != $3
        """,
        order_id, error_desc, payment_id,
    )
    return res != "UPDATE 0"


async def get_cycle_paid(db, student_id: int, cycle_start: date) -> int:
    return await db.fetchval(
        """
        select coalesce(sum(amount), 0)::integer
        from payment
        where student_id = $1
          and cycle_start = $2
          and coalesce(isactive, true)
          and coalesce(status::text, 'active') = 'active'
        """,
        student_id, cycle_start,
    )


async def update_allow_partial_payment(
    db, student_id: int, allow: bool, amount: int | None = None
) -> None:
    await db.execute(
        "update students set allow_partial_payment = $2, partial_payment_amount = $3, updated_at = now() where id = $1",
        student_id, allow, amount,
    )


async def consume_partial_payment_approval(db, student_id: int) -> None:
    await db.execute(
        "update students set allow_partial_payment = false, partial_payment_amount = null, updated_at = now() where id = $1",
        student_id,
    )


async def mark_order_paid(db, order_pk: int, razorpay_payment_id: str, payment_id: int) -> None:
    await db.execute(
        """
        update payment_order
        set status = 'paid', razorpay_payment_id = $2, payment_id = $3, paid_at = now()
        where id = $1
        """,
        order_pk, razorpay_payment_id, payment_id,
    )

