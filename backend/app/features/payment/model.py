
from typing import Optional

from app.core import enums
from app.core.enums import PaymentCategory, PaymentMode, PaymentStatus, PaymentType
from pydantic import AwareDatetime, BaseModel, Field


class PaymentCreate(BaseModel):
    payment_type: PaymentType
    amount: int
    payment_category: PaymentCategory
    mode: enums.PaymentMode
    isActive:bool
    txn_ref: Optional[str] = Field(
        None, description='Gateway transaction reference, if applicable.'
    )
    paid_on: Optional[AwareDatetime] = Field(
        None,
        description='Optional. Omit for a normal in-app payment (backend defaults to\nnow). Set explicitly when admin is backfilling a cash/paper\nregister entry from a past date.\n',
    )


class Payment(BaseModel):
    id: Optional[int] = None
    student_id: Optional[int] = Field(
        None,
        description='Single, non-nullable FK. Always points to an existing student.',
    )
    payment_type: Optional[PaymentType] = None
    payment_category: Optional[PaymentCategory] = None
    amount: Optional[int] = None
    isActive: Optional[bool] = True
    mode: Optional[PaymentMode] = None
    txn_ref: Optional[str] = None
    paid_on: Optional[AwareDatetime] = Field(
        None,
        description='Either backend-assigned (now) or admin-supplied at creation - not regenerated afterward.',
    )
    status: Optional[PaymentStatus] = PaymentStatus.active
    superseded_by: Optional[int] = Field(
        None,
        description='Set only when status = superseded. Points to the Payment.id of\nthe corrected row that replaced this one. Null for active rows.\n',
    )
