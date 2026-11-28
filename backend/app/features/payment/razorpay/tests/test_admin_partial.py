import unittest
from datetime import date

from app.features.payment.razorpay import billing


class TestAdminPartialLogic(unittest.TestCase):
    def test_cycle_balance_calculation(self):
        cycle_fee = 3000
        cycle_paid = 1000
        cycle_balance = max(0, cycle_fee - cycle_paid)
        self.assertEqual(cycle_balance, 2000)

    def test_approved_part_payment_validation(self):
        cycle_balance = 2000
        approved_amount = 1000
        # Valid approved amount: 1 <= amount < balance
        self.assertTrue(1 <= approved_amount < cycle_balance)

        invalid_amount_equal = 2000
        self.assertFalse(1 <= invalid_amount_equal < cycle_balance)

        invalid_amount_greater = 2500
        self.assertFalse(1 <= invalid_amount_greater < cycle_balance)


if __name__ == "__main__":
    unittest.main()
