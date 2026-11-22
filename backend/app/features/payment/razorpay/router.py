from fastapi import APIRouter, Depends

from app.core.auth.auth import get_current_user, is_admin, require_admin
from app.core.db import get_db

from . import service
from .models import (
    CheckoutOptions, FeeStatusResponse, OrderStatusResponse,
    PartialPaymentSwitchRequest, SimpleCreateOrderRequest, SimpleCreateOrderResponse,
    SimpleVerifyPaymentRequest, SimpleVerifyPaymentResponse,
    StartPaymentRequest, VerifyPaymentRequest, VerifyPaymentResponse,
)

router = APIRouter(prefix="/payments", tags=["Razorpay"])


@router.post("/create-order", response_model=SimpleCreateOrderResponse)
async def create_order(body: SimpleCreateOrderRequest):
    """Create a Razorpay order with amount (in paise), currency, and optional receipt."""
    return await service.create_simple_order(body)


@router.post("/verify-payment", response_model=SimpleVerifyPaymentResponse)
async def verify_payment_simple(body: SimpleVerifyPaymentRequest):
    """Verify Razorpay payment HMAC-SHA256 signature."""
    return await service.verify_simple_payment(body)


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
    """Fee amount, paid-till date and next due date for the Pay Fees screen (Admin or owning student)."""
    admin_flag = await is_admin(user, db)
    return await service.get_fee_status(db, user, student_id, is_admin_user=admin_flag)


@router.patch("/student/{student_id}/partial-payment", response_model=FeeStatusResponse)
async def patch_partial_payment(
    student_id: int, body: PartialPaymentSwitchRequest, db=Depends(get_db), admin=Depends(require_admin)
):
    """Admin endpoint to enable/disable partial payments for a student's current cycle."""
    return await service.toggle_partial_payment(db, student_id, body.allow_partial_payment)
