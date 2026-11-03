"""Raw SQL for the online-payment flow. `db` is an asyncpg connection."""
import uuid
from datetime import date

_STUDENT_COLS = """
    id, name, contact, email, fees, fee_type::text as fee_type,
    fee_paid_till, date_of_joining
"""


async def lock_student_orders(db, student_id: int) -> None:
    """Serialise order creation per student (released at transaction end)."""
    await db.execute("select pg_advisory_xact_lock(1001, $1)", student_id)


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


async def find_reusable_order(db, student_id: int, amount_paise: int, cycles: int) -> str | None:
    return await db.fetchval(
        """
        select razorpay_order_id from payment_order
        where student_id = $1 and status = 'created'
          and amount_paise = $2 and cycles = $3
          and created_at > now() - interval '1 day'
        order by id desc limit 1
        """,
        student_id, amount_paise, cycles,
    )


async def insert_order(db, student_id: int, razorpay_order_id: str, amount_paise: int, cycles: int) -> None:
    await db.execute(
        """
        insert into payment_order (student_id, razorpay_order_id, amount_paise, cycles)
        values ($1, $2, $3, $4)
        """,
        student_id, razorpay_order_id, amount_paise, cycles,
    )


async def get_order(db, razorpay_order_id: str):
    return await db.fetchrow(
        """
        select id, student_id, razorpay_order_id, amount_paise, cycles, status, payment_id
        from payment_order where razorpay_order_id = $1
        """,
        razorpay_order_id,
    )


async def lock_order(db, razorpay_order_id: str):
    return await db.fetchrow(
        """
        select id, student_id, razorpay_order_id, amount_paise, cycles, status, payment_id
        from payment_order where razorpay_order_id = $1 for update
        """,
        razorpay_order_id,
    )


async def has_active_payment(db, student_id: int) -> bool:
    return await db.fetchval(
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


async def insert_payment(
    db, student_id: int, payment_type: str, amount_rupees: int,
    mode: str, txn_ref: str, category: str,
) -> int:
    return await db.fetchval(
        """
        insert into payment (student_id, payment_type, amount, mode, txn_ref, payment_category)
        values ($1, $2::payment_type, $3, $4::payment_mode, $5, $6::payment_cat)
        returning id
        """,
        student_id, payment_type, amount_rupees, mode, txn_ref, category,
    )


async def advance_fee_paid_till(db, student_id: int, paid_till: date) -> None:
    await db.execute(
        "update students set fee_paid_till = $2, updated_at = now() where id = $1",
        student_id, paid_till,
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
