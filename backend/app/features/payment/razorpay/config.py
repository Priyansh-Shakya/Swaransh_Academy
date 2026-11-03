import os
from dataclasses import dataclass

from dotenv import load_dotenv

load_dotenv()


def _require(name: str) -> str:
    value = os.getenv(name)
    if not value:
        raise RuntimeError(f"Missing required environment variable: {name}")
    return value


@dataclass(frozen=True)
class RazorpaySettings:
    key_id: str
    key_secret: str       # backend only, never sent to the app
    webhook_secret: str   # separate from key secret; you choose it in the dashboard
    academy_name: str
    api_base: str = "https://api.razorpay.com/v1"


settings = RazorpaySettings(
    key_id=_require("RAZORPAY_KEY_ID"),
    key_secret=_require("RAZORPAY_KEY_SECRET"),
    webhook_secret=_require("RAZORPAY_WEBHOOK_SECRET"),
    academy_name=os.getenv("ACADEMY_NAME", "Swaransh Academy"),
)
