-- Migration: Admin-set partial payment amount for students

ALTER TABLE public.students
  ADD COLUMN IF NOT EXISTS partial_payment_amount INTEGER NULL CHECK (partial_payment_amount IS NULL OR partial_payment_amount > 0);

-- Note: Run the following manually if resetting existing partial payment approvals:
-- UPDATE students SET allow_partial_payment = false, partial_payment_amount = null WHERE allow_partial_payment;
