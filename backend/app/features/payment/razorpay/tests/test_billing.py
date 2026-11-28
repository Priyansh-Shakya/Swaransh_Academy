import unittest
from datetime import date

from app.features.payment.razorpay.billing import (
    coverage,
    current_cycle,
    cycle_label,
    cycle_start,
    fee_to_rupees,
    normalize_fee_type,
)


class TestBillingHelpers(unittest.TestCase):
    def test_normalize_fee_type(self):
        self.assertEqual(normalize_fee_type("monthly"), "monthly")
        self.assertEqual(normalize_fee_type("Monthly "), "monthly")
        self.assertEqual(normalize_fee_type("Half-Yearly"), "half_yearly")
        self.assertEqual(normalize_fee_type("quarterly"), "quarterly")
        self.assertEqual(normalize_fee_type("yearly"), "yearly")
        with self.assertRaises(ValueError):
            normalize_fee_type("invalid_type")

    def test_fee_to_rupees(self):
        self.assertEqual(fee_to_rupees(2500.0), 2500)
        self.assertEqual(fee_to_rupees(500), 500)
        with self.assertRaises(ValueError):
            fee_to_rupees(2500.50)  # Rejects paise
        with self.assertRaises(ValueError):
            fee_to_rupees(0)
        with self.assertRaises(ValueError):
            fee_to_rupees(-100)

    def test_cycle_start(self):
        joining = date(2026, 1, 15)
        # When fee_paid_till is None, cycle starts from date_of_joining
        self.assertEqual(cycle_start(None, joining), joining)
        # When fee_paid_till is set, cycle starts the next day
        self.assertEqual(
            cycle_start(date(2026, 2, 14), joining), date(2026, 2, 15)
        )

    def test_coverage(self):
        joining = date(2026, 1, 15)
        # 1 cycle monthly
        start, end = coverage(None, joining, "monthly", cycles=1)
        self.assertEqual(start, date(2026, 1, 15))
        self.assertEqual(end, date(2026, 2, 14))

        # 1 cycle quarterly
        start, end = coverage(date(2026, 2, 14), joining, "quarterly", cycles=1)
        self.assertEqual(start, date(2026, 2, 15))
        self.assertEqual(end, date(2026, 5, 14))

    def test_current_cycle(self):
        joining = date(2026, 11, 21)
        start, end = current_cycle(None, joining, "monthly")
        self.assertEqual(start, date(2026, 11, 21))
        self.assertEqual(end, date(2026, 12, 20))

    def test_cycle_label_same_year(self):
        start = date(2026, 11, 21)
        end = date(2026, 12, 20)
        self.assertEqual(cycle_label(start, end), "21 Nov to 20 Dec 2026")

    def test_cycle_label_cross_year(self):
        start = date(2026, 12, 20)
        end = date(2027, 1, 19)
        self.assertEqual(cycle_label(start, end), "20 Dec 2026 to 19 Jan 2027")

    def test_cycle_label_leap_year(self):
        start = date(2028, 2, 1)
        end = date(2028, 2, 29)
        self.assertEqual(cycle_label(start, end), "01 Feb to 29 Feb 2028")


if __name__ == "__main__":
    unittest.main()
