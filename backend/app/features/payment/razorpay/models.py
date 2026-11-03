from datetime import date
from typing import Literal, Optional

from pydantic import BaseModel, Field


class StartPaymentRequest(BaseModel):
    student_id: int
    cycles: int = Field(
        1, ge=1, le=12,
        description="Number of fee cycles to pay for (1 = the current due cycle).",
    )


class Prefill(BaseModel):
    name: Optional[str] = None
    contact: Optional[str] = None
    email: Optional[str] = None


class CheckoutOptions(BaseModel):
    """Everything the app needs to open Razorpay checkout."""
    key_id: str
    order_id: str
    amount: int = Field(..., description="Amount in paise")
    currency: str = "INR"
    name: str
    description: str
    prefill: Prefill
    cycles: int
    covers_from: date
    covers_till: date


class VerifyPaymentRequest(BaseModel):
    razorpay_order_id: str
    razorpay_payment_id: str
    razorpay_signature: str


class VerifyPaymentResponse(BaseModel):
    status: Literal["paid", "pending"]
    payment_id: Optional[int] = None
    fee_paid_till: Optional[date] = None


class OrderStatusResponse(BaseModel):
    razorpay_order_id: str
    status: Literal["created", "paid"]
    fee_paid_till: Optional[date] = None


class FeeStatusResponse(BaseModel):
    student_id: int
    fee_type: str
    fee_amount: int = Field(..., description="Fee per cycle, in rupees")
    fee_paid_till: Optional[date] = None
    next_due_date: date
    is_due: bool
