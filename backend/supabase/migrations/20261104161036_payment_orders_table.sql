-- Pending / settled Razorpay orders. The existing "payment" table stays settled-money-only.
create table if not exists public.payment_order (
  id bigint generated always as identity primary key,
  student_id bigint not null references public.students (id) on delete cascade,
  razorpay_order_id text not null unique,
  amount_paise bigint not null check (amount_paise > 0),
  cycles integer not null check (cycles between 1 and 12),
  status text not null default 'created' check (status in ('created', 'paid')),
  razorpay_payment_id text unique,
  payment_id bigint references public.payment (id) on delete set null,
  created_at timestamptz not null default now(),
  paid_at timestamptz
);
create index if not exists idx_payment_order_student_status
  on public.payment_order (student_id, status);
-- ---------------------------------------------------------------------------
-- Helper (run manually, BEFORE going live): students with no fee_paid_till.
-- Decide each student's real "paid up to" date, then update, e.g.:
--   update students set fee_paid_till = date '2026-11-30' where id = 12;
-- A null fee_paid_till means billing starts from date_of_joining.
-- ---------------------------------------------------------------------------
-- select s.id, s.name, s.fee_type, s.date_of_joining, max(p.paid_on) as last_paid_on
-- from public.students s
-- left join public.payment p
--   on p.student_id = s.id and coalesce(p.isactive, true) and coalesce(p.status::text, 'active') = 'active'
-- where s.fee_paid_till is null
-- group by s.id
-- order by s.id;
