from fastapi import APIRouter, Depends, Header, Request

from app.core.db import get_db

from . import service

# No auth dependency: Razorpay calls this. Security is the HMAC signature check.
router = APIRouter(prefix="/webhooks", tags=["Razorpay Webhook"])


@router.post("/razorpay")
async def razorpay_webhook(
    request: Request,
    x_razorpay_signature: str | None = Header(default=None),
    db=Depends(get_db),
):
    raw_body = await request.body()  # signature is computed over the RAW bytes
    await service.handle_webhook(db, raw_body, x_razorpay_signature)
    return {"status": "ok"}
