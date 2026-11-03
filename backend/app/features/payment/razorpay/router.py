from fastapi import APIRouter, Depends

from app.core.auth.auth import get_current_user
from app.core.db import get_db

from . import service
from .models import (
    CheckoutOptions, FeeStatusResponse, OrderStatusResponse,
    StartPaymentRequest, VerifyPaymentRequest, VerifyPaymentResponse,
)

router = APIRouter(prefix="/payments", tags=["Razorpay"])


@router.post("/start", response_model=CheckoutOptions)
async def start_payment(
    body: StartPaymentRequest, db=Depends(get_db), user=Depends(get_current_user)
):
    """Create (or reuse) a Razorpay order for a student's fee and return checkout options."""
    return await service.start_payment(db, user, body)


@router.post("/verify", response_model=VerifyPaymentResponse)
async def verify_payment(
    body: VerifyPaymentRequest, db=Depends(get_db), user=Depends(get_current_user)
):
    """Called by the app after checkout succeeds, for fast feedback."""
    return await service.verify_payment(db, user, body)


@router.get("/order/{razorpay_order_id}/status", response_model=OrderStatusResponse)
async def order_status(
    razorpay_order_id: str, db=Depends(get_db), user=Depends(get_current_user)
):
    """Poll this after checkout until status == 'paid'."""
    return await service.get_order_status(db, user, razorpay_order_id)


@router.get("/student/{student_id}/fee-status", response_model=FeeStatusResponse)
async def fee_status(
    student_id: int, db=Depends(get_db), user=Depends(get_current_user)
):
    """Fee amount, paid-till date and next due date for the Pay Fees screen."""
    return await service.get_fee_status(db, user, student_id)
