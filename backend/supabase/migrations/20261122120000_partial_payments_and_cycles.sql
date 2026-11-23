-- Migration: Partial Payments, Billing Cycles & Razorpay Error Tracking

ALTER TABLE public.payment
  ADD COLUMN IF NOT EXISTS cycle_start DATE,
  ADD COLUMN IF NOT EXISTS cycle_end DATE,
  ADD COLUMN IF NOT EXISTS cycle_fee INTEGER;

CREATE INDEX IF NOT EXISTS idx_payment_student_cycle
  ON public.payment (student_id, cycle_start);

ALTER TABLE public.students
  ADD COLUMN IF NOT EXISTS allow_partial_payment BOOLEAN NOT NULL DEFAULT FALSE;

ALTER TABLE public.payment_order
  ADD COLUMN IF NOT EXISTS cycle_start DATE,
  ADD COLUMN IF NOT EXISTS cycle_end DATE,
  ADD COLUMN IF NOT EXISTS cycle_fee INTEGER,
  ADD COLUMN IF NOT EXISTS last_error TEXT,
  ADD COLUMN IF NOT EXISTS last_error_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS last_failed_payment_id TEXT;
