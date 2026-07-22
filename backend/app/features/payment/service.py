"""Service for Payment operations"""

from typing import List

from app.core.helper import convert_enums_to_values
from app.features.payment import repository
from app.features.payment.model import Payment, PaymentCreate


async def create_payment(student_id: int, payment_create: PaymentCreate, db) -> Payment:
    """
    Record a new payment.
    
    If paid_on is not specified, backend defaults to now().
    """
    data = payment_create.model_dump(mode='python')
    data = convert_enums_to_values(data)
    
    # Extract values
    payment_type = data.get('payment_type')
    payment_category = data.get('payment_category')
    amount = data.get('amount')
    mode = data.get('mode')
    txn_ref = data.get('txn_ref')
    paid_on = data.get('paid_on')  # Can be None, defaults to now() in query
    
    # Create payment
    row = await db.fetchrow(
        repository.create_payment_query,
        student_id,
        payment_type,
        int(amount) if amount else 0,  # Store as minor units (cents)
        mode,
        txn_ref,
        paid_on,
        'active',  # status,
        payment_category, 
        True #! Client is not sending isActive , backend is asigning default
    )
    
    payment_dict = dict(row)
    return Payment(**payment_dict)


async def get_payment(payment_id: int, db) -> Payment:
    """Get payment by ID"""
    row = await db.fetchrow(repository.get_payment_by_id_query, payment_id)
    if not row:
        raise ValueError(f"Payment {payment_id} not found")
    return Payment(**dict(row))


async def correct_payment(
    student_id: int,
    payment_id: int,
    payment_create: PaymentCreate,
    db
) -> Payment:
    """
    Correct a payment using the supersede pattern:
    1. Insert a new corrected payment with status='active'
    2. Mark the old payment with status='superseded' and superseded_by=new_id
    
    This preserves an audit trail while allowing corrections.
    """
    data = payment_create.model_dump(mode='python')
    data = convert_enums_to_values(data)
    
    # Extract values
    payment_type = data.get('payment_type')
    payment_category = data.get('payment_category')
    amount = data.get('amount')
    mode = data.get('mode')
    txn_ref = data.get('txn_ref')
    paid_on = data.get('paid_on')
    
    # Create new corrected payment
    new_row = await db.fetchrow(
        repository.create_corrected_payment_query,
        student_id,
        payment_type,
        int(amount) if amount else 0,
        mode,
        txn_ref,
        paid_on,
        payment_category

    )
    
    new_payment_id = new_row['id']
    
    # Mark old payment as superseded
    await db.fetchrow(
        repository.supersede_payment_query,
        new_payment_id,
        payment_id
    )
    
    return Payment(**dict(new_row))


async def delete_payment(payment_id: int, db) -> None:
    """
    Hard delete a payment (reserved for genuine duplicates).
    """
    await db.execute(repository.delete_payment_query, payment_id)


async def get_payment_history(student_id: int, db) -> List[Payment]:
    """Get payment history for a student"""
    rows = await db.fetch(repository.get_payments_by_student_query, student_id)
    return [Payment(**dict(row)) for row in rows]


async def get_all_payments(db) -> List[Payment]:
    """Get all payments (admin view)"""
    rows = await db.fetch(repository.get_all_payments_query)
    return [Payment(**dict(row)) for row in rows]
