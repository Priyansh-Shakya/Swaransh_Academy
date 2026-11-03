"""Pure billing helpers: no DB, no network. Easy to unit test."""
import calendar
from datetime import date, datetime, timedelta
from decimal import Decimal, InvalidOperation
from zoneinfo import ZoneInfo

IST = ZoneInfo("Asia/Kolkata")

FEE_TYPE_MONTHS = {
    "monthly": 1,
    "quarterly": 3,
    "half_yearly": 6,
    "yearly": 12,
}


def today_ist() -> date:
    return datetime.now(IST).date()


def normalize_fee_type(value: str) -> str:
    key = str(value).strip().lower().replace(" ", "_").replace("-", "_")
    if key not in FEE_TYPE_MONTHS:
        raise ValueError(f"Unsupported fee_type: {value!r}")
    return key


def fee_to_rupees(fees: float) -> int:
    """Convert students.fees (double) to whole rupees. Refuses paise instead of rounding money."""
    try:
        amount = Decimal(str(fees))
    except InvalidOperation:
        raise ValueError(f"Invalid fee amount: {fees!r}")
    if amount <= 0:
        raise ValueError("Fee must be greater than zero")
    if amount != amount.to_integral_value():
        raise ValueError(
            "Fee is not a whole-rupee amount; ask an admin to correct the student's fees"
        )
    return int(amount)


def _add_months(start: date, months: int, anchor_day: int) -> date:
    index = start.month - 1 + months
    year = start.year + index // 12
    month = index % 12 + 1
    day = min(anchor_day, calendar.monthrange(year, month)[1])
    return date(year, month, day)


def cycle_start(fee_paid_till: date | None, date_of_joining: date) -> date:
    """First day not yet paid for. fee_paid_till is the last covered day, inclusive."""
    return fee_paid_till + timedelta(days=1) if fee_paid_till else date_of_joining


def _anchor_day(start: date, joining: date) -> int:
    # Keep the joining day-of-month (31st -> 28th -> 31st) so dates don't drift earlier.
    # If an admin backfilled an unaligned date, anchor on that date instead.
    expected = min(joining.day, calendar.monthrange(start.year, start.month)[1])
    return joining.day if start.day == expected else start.day


def coverage(
    fee_paid_till: date | None,
    date_of_joining: date,
    fee_type: str,
    cycles: int,
) -> tuple[date, date]:
    """Returns (covers_from, covers_till), both inclusive, for `cycles` cycles."""
    months = FEE_TYPE_MONTHS[normalize_fee_type(fee_type)] * cycles
    start = cycle_start(fee_paid_till, date_of_joining)
    end_exclusive = _add_months(start, months, _anchor_day(start, date_of_joining))
    return start, end_exclusive - timedelta(days=1)
