from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException

from app.core.auth.auth import check_role, get_current_user, require_admin
from app.core.db import get_db
from app.features.payment import service
from app.features.payment.model import Payment, PaymentCreate

router = APIRouter(tags=['Payments'])


@router.post('/student/{id}/payment', response_model=Payment, tags=['Payments'])
async def post_student_id_payment(
    id: int, body: PaymentCreate, db=Depends(get_db), admin=Depends(require_admin)
) -> Payment:
    """Record a Payment (Admin only)."""
    return await service.create_payment(id, body, db)


@router.put('/student/{id}/payment/{payment_id}', response_model=Payment, tags=['Payments'])
async def put_student_id_payment_payment_id(
    id: int, payment_id: int, body: PaymentCreate, db=Depends(get_db), admin=Depends(require_admin)
) -> Payment:
    """Correct a Payment (supersede, Admin only)."""
    return await service.correct_payment(id, payment_id, body, db)


@router.delete('/student/{id}/payment/{payment_id}', response_model=None, tags=['Payments'])
async def delete_student_id_payment_payment_id(
    id: int, payment_id: int, db=Depends(get_db), admin=Depends(require_admin)
) -> None:
    """Delete a Payment (hard delete, Admin only)."""
    await service.delete_payment(id, payment_id, db)


@router.get('/student/{id}/paymentList', response_model=list[Payment], tags=['Payments'])
async def get_student_id_payment_list(
    id: int, db=Depends(get_db), user=Depends(get_current_user)
) -> list[Payment]:
    """Get Payment History for a Student (Admin or owning student)."""
    role = await check_role(user, db)
    if role != 'admin':
        owner_id = await db.fetchval("select user_id from students where id = $1", id)
        if not owner_id or str(owner_id) != str(user['id']):
            raise HTTPException(403, detail="Forbidden: You can only view your own payment history")
    return await service.get_payment_history(id, db)
