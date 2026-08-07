
CREATE TYPE payment_cat AS ENUM (
    'fee',
    'admission',
    'other'
);

ALTER TABLE public.payment
ADD COLUMN payment_category public.payment_cat NOT NULL;

ALTER TABLE public.payment
ADD COLUMN isActive boolean DEFAULT true;