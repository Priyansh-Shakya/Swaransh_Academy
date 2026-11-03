"""Razorpay gateway adapter. No database access here."""
import hashlib
import hmac

import httpx

from .config import settings


class RazorpayError(Exception):
    def __init__(self, message: str, status_code: int | None = None):
        super().__init__(message)
        self.status_code = status_code


_http: httpx.AsyncClient | None = None


def _client() -> httpx.AsyncClient:
    global _http
    if _http is None:
        _http = httpx.AsyncClient(
            base_url=settings.api_base,
            auth=(settings.key_id, settings.key_secret),
            timeout=httpx.Timeout(15.0),
        )
    return _http


async def close_client() -> None:
    """Call from your app shutdown/lifespan."""
    global _http
    if _http is not None:
        await _http.aclose()
        _http = None


async def _request(method: str, path: str, **kwargs) -> dict:
    try:
        resp = await _client().request(method, path, **kwargs)
    except httpx.HTTPError as exc:
        raise RazorpayError(f"Network error talking to Razorpay: {exc}") from exc

    if resp.status_code >= 400:
        try:
            detail = resp.json().get("error", {}).get("description", resp.text)
        except ValueError:
            detail = resp.text
        raise RazorpayError(detail, status_code=resp.status_code)
    return resp.json()


async def create_order(amount_paise: int, receipt: str, notes: dict[str, str]) -> dict:
    return await _request(
        "POST",
        "/orders",
        json={
            "amount": amount_paise,
            "currency": "INR",
            "receipt": receipt,   # max 40 chars
            "notes": notes,
        },
    )


async def fetch_payment(payment_id: str) -> dict:
    return await _request("GET", f"/payments/{payment_id}")


def verify_checkout_signature(order_id: str, payment_id: str, signature: str) -> bool:
    expected = hmac.new(
        settings.key_secret.encode(),
        f"{order_id}|{payment_id}".encode(),
        hashlib.sha256,
    ).hexdigest()
    return hmac.compare_digest(expected, signature or "")


def verify_webhook_signature(raw_body: bytes, signature: str | None) -> bool:
    if not signature:
        return False
    expected = hmac.new(
        settings.webhook_secret.encode(), raw_body, hashlib.sha256
    ).hexdigest()
    return hmac.compare_digest(expected, signature)
