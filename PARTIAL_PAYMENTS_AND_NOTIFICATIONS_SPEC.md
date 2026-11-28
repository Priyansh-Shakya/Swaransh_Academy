# Swaransh Academy: Partial Payments, Billing Cycles, Push Notifications

**Audience:** an AI coding agent working in both repos (FastAPI backend with asyncpg and raw SQL, Flutter app with Riverpod and Dio).
**Status of this document:** written by someone who could not see the current code. File names, function names, and column names below are the *last known* state. **Treat every name as an assumption. Read the real code first, adapt to it, and do not blindly overwrite files.**

---

## 0. How to work (read first)

1. Before changing anything, inspect the current code and write a short "current state vs this spec" note listing every difference you find (file names, function names, column names, enum labels). Then proceed, adapting to the real code.
2. Work in the phases of section 11, one phase at a time, with small commits on the feature branch. After each phase, run the app/tests and stop for review.
3. Do **not** remove or weaken any invariant in section 2.
4. When this spec says "verify", actually run a grep or query. Do not assume.
5. Never put secrets in code or git. All Razorpay secrets are server env vars.

---

## 1. Background: what exists today (last known)

### Stack
- Backend: FastAPI, asyncpg, raw SQL, `get_db` (yields an asyncpg connection) in `app/core/db.py`, `get_current_user` in `app/core/auth/auth.py` (returns a dict with `id`, a UUID matching `students.user_id`). Hosted on Render **free tier**.
- Razorpay integration lives in `app/features/payment/razorpay/`: `config.py`, `client.py` (httpx REST calls and HMAC checks, no SDK), `billing.py` (pure date/money helpers), `models.py`, `repository.py`, `service.py`, `router.py`, `webhook_router.py`.
- Manual (admin) payment endpoints live in `app/features/payment/` (`router.py`, `service.py`, `repository.py`, `model.py`). They expose `POST /student/{id}/payment`, `PUT /student/{id}/payment/{payment_id}` (supersede), `DELETE ...`, `GET /student/{id}/paymentList`. They currently **do not touch `fee_paid_till`** and **do not check the caller's role**.
- Flutter: `lib/features/payments/` with `domain/checkout_models.dart`, `data/razorpay_api_service.dart`, `providers/online_payment_notifier.dart` (Riverpod `AutoDisposeFamilyAsyncNotifier`, family key = studentId, owns the Razorpay SDK instance, plus `feeStatusProvider`), `presentation/pay_fees_button.dart` (builder-style `ConsumerWidget`). The old `StateNotifier` `paymentProvider` (payment history) also exists. The student profile screen has a `_FeesCard` widget.

### Existing online flow
1. `POST /payments/start {student_id, cycles}`: backend reads fee from DB, creates (or reuses) a Razorpay order, inserts a `payment_order` row (`status='created'`), returns checkout options.
2. App opens Razorpay checkout, then calls `POST /payments/verify` (HMAC check + fetch payment from Razorpay; settles only if `status == captured`), then polls `GET /payments/order/{id}/status`.
3. `POST /webhooks/razorpay` (HMAC-verified over the raw body) handles `payment.captured` and `order.paid`. It calls the same `settle_order`.
4. `settle_order` (idempotent): in one transaction it locks the `payment_order` row, checks the paid amount equals the order amount, locks the student row, inserts a `payment` row (first-ever payment → type `admission` and category `admission`, else type = student's `fee_type` and category `fee`; mode from Razorpay method: upi→`upi`, card→`card`, netbanking→`bank_transfer`, else `other`; `txn_ref` = Razorpay payment id), advances `students.fee_paid_till` by `cycles` × fee-type length, and marks the order paid.

### Existing DB facts
- `students`: `id`, `user_id uuid`, `name`, `fees double precision`, `fee_type` (enum: monthly/quarterly/half_yearly/yearly, **verify exact labels**, possibly "half yearly" with a space), `fee_paid_till date`, `date_of_joining date`, `status` (enum, includes a value like `pending_payment`, **verify**), `contact`, `email`, etc.
- `payment`: `id`, `student_id`, `payment_type` (enum: admission, monthly, quarterly, half_yearly, yearly), `amount bigint` (whole rupees), `mode` (enum: cash, upi, card, bank_transfer, other), `txn_ref`, `paid_on timestamptz default now()`, `status` (enum payment_status: active, superseded), `superseded_by`, `payment_category` (enum payment_cat: fee, admission, other), `isactive boolean default true`.
- `payment_order`: `id`, `student_id`, `razorpay_order_id unique`, `amount_paise`, `cycles`, `status ('created'|'paid')`, `razorpay_payment_id`, `payment_id`, `created_at`, `paid_at`.
- `fee_paid_till` semantics: the **last day (inclusive) that fees cover**. Next unpaid day = `fee_paid_till + 1`, or `date_of_joining` if null. Pay-first, learn-after model. Student is due when `fee_paid_till` is null or `< today` (IST).
- Cycle length from fee type: monthly 1, quarterly 3, half_yearly 6, yearly 12 months. `billing.coverage(fee_paid_till, date_of_joining, fee_type, cycles)` returns `(covers_from, covers_till)` and anchors on the joining day-of-month so the 31st doesn't drift. It has unit-tested edge cases. **Reuse it, don't reimplement.**

---

## 2. Invariants (must remain true)

1. The **amount is never trusted from the app**. The backend derives or validates it from its own DB data.
2. `HMAC` signature checks on `/payments/verify` and `/webhooks/razorpay` stay. The webhook must read the **raw body**.
3. Settlement is **idempotent** and race-safe: verify and webhook may arrive in any order, twice, or concurrently, and credit exactly once (order row lock `FOR UPDATE`, status flip).
4. Money handling is integer only. `students.fees` (double) converts via the existing whole-rupee check (`billing.fee_to_rupees`), which rejects paise instead of rounding.
5. Notifications and (future) emails run **after the DB transaction commits** and may **never** make a payment or webhook fail. Wrap in try/except, log, and move on.
6. The webhook returns 200 for unknown orders and amount mismatches (logged), and non-200 only for genuine server errors, so Razorpay retries only when useful.
7. Online payments only ever credit money that Razorpay reports as `captured`.

---

## 3. Decisions made (implement exactly this)

### 3.1 Cycle model
Every fee payment belongs to a **billing cycle**.

- **Current cycle** of a student: `start = fee_paid_till + 1 day` (or `date_of_joining` if null), `end` = `billing.coverage(..., cycles=1)[1]`.
- **Cycle fee** = `billing.fee_to_rupees(students.fees)` (whole rupees).
- **Cycle paid** = sum of `payment.amount` for that student where `cycle_start` = the cycle's start, `isactive` is true, `status = 'active'`.
- **Balance** = `cycle_fee - cycle_paid`.
- `fee_paid_till` moves to `cycle_end` **only when cycle paid ≥ cycle fee**. Part payments never move it.
- Advance rule: `new = GREATEST(existing fee_paid_till, cycle_end)`. Automatic logic never moves the date backwards.
- Students pay **one cycle at a time**. The old `cycles` concept (paying several cycles at once) is removed from the API. Keep the DB column `payment_order.cycles` (do not drop it) but always write 1 and stop exposing it.

### 3.2 Month tracking: no separate month table
Months are tracked by `cycle_start`, `cycle_end`, and `cycle_fee` stored on each payment row. No other month or period table is needed.

### 3.3 Partial payment switch
- Add a single boolean `students.allow_partial_payment`, **default false**.
- Meaning: "this student may pay part of the *current* cycle online".
- Admins flip it on or off from the admin student detail screen.
- **Auto-reset:** whenever a cycle becomes fully paid (the advance rule above fires), set `allow_partial_payment = false` in the same transaction. This gives "partial allowed this cycle only" behaviour with no month-tracking table. Admins can also flip it any time.
- Minimum part payment: a **global** setting, env var `MIN_PARTIAL_PAYMENT_RUPEES`, default `100`. Read it in the existing config module. If the cycle fee or balance is smaller than the minimum, paying the full balance is still allowed.
- The switch gates **student-initiated online partial payments only**. **Admin manual entries may be partial regardless of the switch.**

### 3.4 Payment-allowed rule (the "no paying for the future" guard)
`can_pay` is true only if `fee_paid_till IS NULL OR fee_paid_till < today (Asia/Kolkata)`. Otherwise the student is paid up. The backend enforces this in `/payments/start` (409 response); the app also disables the button.

### 3.5 Manual payments
- Category `fee` and `admission`: go through the shared write function (section 5), target the student's current cycle, and are validated (section 5.3).
- Category `other`: plain insert, cycle columns null, no effect on `fee_paid_till`.
- New optional request flag `record_only: bool = false`: plain ledger insert, cycle columns null, no effect on `fee_paid_till`. This is the escape hatch for historical backfills, where admins set `students.fee_paid_till` directly and record payments without affecting the date.
- Corrections (PUT, supersede) and deletes: **do not touch `fee_paid_till`** (rollback is a later feature). The superseding row **inherits** `cycle_start`, `cycle_end`, `cycle_fee` from the row it replaces, unless the request says otherwise. Because cycle-paid sums only count active rows, balances update, but the date stays until an admin fixes it by editing the student. The app should show a reminder after delete or correct ("Check this student's Paid Till date.").

### 3.6 Overpayment at online settlement
Money Razorpay captured is always recorded. If an online payment lands on a cycle that became fully paid in the meantime (e.g. an admin recorded cash while checkout was open), record it against the order's cycle anyway, and compute `overpaid_by = max(0, cycle_paid_after - cycle_fee)`. If `overpaid_by > 0`, send an **admin** push ("Overpayment ... refund or treat as advance") and log it. Do not auto-refund.

---

## 4. Database migration (new file, e.g. `migrations/002_partial_payments_and_cycles.sql`)

Use `if not exists` and make it re-runnable. Verify actual table names first.

```sql
alter table public.payment
  add column if not exists cycle_start date,
  add column if not exists cycle_end   date,
  add column if not exists cycle_fee   integer;

create index if not exists idx_payment_student_cycle
  on public.payment (student_id, cycle_start);

alter table public.students
  add column if not exists allow_partial_payment boolean not null default false;

alter table public.payment_order
  add column if not exists cycle_start date,
  add column if not exists cycle_end   date,
  add column if not exists cycle_fee   integer,
  add column if not exists last_error text,
  add column if not exists last_error_at timestamptz,
  add column if not exists last_failed_payment_id text;
```

Notes:
- All new `payment` columns are nullable. Existing rows and `other`-category rows stay null and are ignored by cycle sums.
- Do not drop `payment_order.cycles`.
- Update any Pydantic models and SELECT lists that return full payment or student rows so the new fields flow through.

---

## 5. Backend: the shared write function

### 5.1 Structure (two parts, so notifications run after commit)
Create one module (suggestion: `app/features/payment/ledger.py`) with:

1. **`apply_payment(db, ...)`**: DB work only. Must be called **inside an open transaction**, and it must itself take the student row lock (`select ... from students where id=$1 for update`). It returns a result object (`PaymentResult`) with: `payment_id`, `student_id`, `amount`, `cycle_start`, `cycle_end`, `cycle_fee`, `cycle_paid_after`, `balance_after`, `completed` (bool), `overpaid_by`, `fee_paid_till_after`, `payment_type`, `category`, `mode`, `source` (`online` or `manual`).
2. **`notify_payment_result(...)`** (and `notify_payment_failed(...)`): push sending, called by the *callers* after their transaction commits (section 8).

### 5.2 What `apply_payment` does
Inputs: connection, `student_id`, `amount_rupees`, `payment_type`, `category`, `mode`, `txn_ref`, optional `paid_on`, optional explicit `cycle` (start, end, fee) and `source`.

1. Lock the student row.
2. If category is `other` or the caller says record-only: plain insert (cycle columns null), return a result with `completed=False`, no date change, no notification of partial or balance.
3. Determine the cycle:
   - **Online settlement:** use the cycle snapshot stored on the `payment_order` row (start, end, fee).
   - **Manual:** compute the student's current cycle fresh (section 3.1).
4. Insert the `payment` row with `cycle_start`, `cycle_end`, `cycle_fee` set.
5. Recompute `cycle_paid_after` by summing active payments for that `(student_id, cycle_start)` (the new row included).
6. If `cycle_paid_after >= cycle_fee`: set `students.fee_paid_till = GREATEST(existing, cycle_end)`, set `allow_partial_payment = false`, set `updated_at = now()`, and set `completed = True`.
7. `overpaid_by = max(0, cycle_paid_after - cycle_fee)`.
8. Status transition: **investigate how `students.status = 'pending_payment'` is currently set and cleared** (grep for it). Whatever the existing logic does when a first payment is recorded, preserve it in this function so the transition happens once the *first cycle is completed* (not on a partial). Do not invent a new status.
9. Return `PaymentResult`.

### 5.3 Validation (manual path only; do it before calling `apply_payment`, inside the same transaction)
- `amount > 0`.
- For fee/admission, non-record-only: `amount <= balance` of the current cycle, otherwise reject with 422: "Amount exceeds the balance of ₹X for this cycle. Record it as two entries." Part payments below the balance are **allowed regardless of `allow_partial_payment`**.
- Do not validate online settlements against balance (see 3.6).

### 5.4 First-payment type rule
Keep the existing rule: if the student has no active `payment` rows at all, the new payment gets `payment_type='admission'` and `payment_category='admission'`; otherwise type = student's `fee_type` and category `fee`. This applies to online payments. For manual entries the admin supplies type and category as they do today.

### 5.5 Callers
- `settle_order` (Razorpay): after locking the order row and passing the amount check, call `apply_payment` with the order's cycle snapshot, then mark the order paid, all in the same transaction. After the commit, send notifications.
- Manual `create_payment`: open a transaction, validate (5.3), call `apply_payment`, commit, notify.
- Manual `correct_payment`: insert the replacement row inheriting cycle columns, mark the old row superseded, no date change, no notifications.
- Manual `delete_payment`: unchanged behaviour (no date change, no notifications).

---

## 6. Backend: endpoints and contracts

### 6.1 `POST /payments/start` (change)
Request (remove `cycles`, add `amount`):
```json
{ "student_id": 13, "amount": 500 }
```
`amount` is optional, in whole rupees. Omit it to pay the full balance.

Logic, in order (inside a transaction holding the existing per-student advisory lock):
1. Ownership: the student must belong to the logged-in user (existing check).
2. If `fee_paid_till` is not null and `>= today (IST)`: **409** `"Fees are already paid until {date}"`.
3. Compute the current cycle, cycle fee, cycle paid and balance. If balance ≤ 0: 409 with the same kind of message.
4. `amount = amount if provided else balance`.
5. If `amount > balance`: **422** `"Amount cannot exceed the balance of ₹{balance}"`.
6. If `amount < balance` (a part payment): require `students.allow_partial_payment == true` (else **422** `"Part payment is not enabled for this student"`) and `amount >= MIN_PARTIAL_PAYMENT_RUPEES` (else **422** with the minimum).
7. Reuse an existing open order (`status='created'`, created < 1 day ago) only if it matches `student_id`, `cycle_start`, and `amount_paise`. Otherwise create a Razorpay order. Notes: `student_id`, `cycle_start`. Insert `payment_order` with `cycle_start`, `cycle_end`, `cycle_fee`, `cycles = 1`.
8. Response (`CheckoutOptions`): keep existing fields; keep `covers_from`/`covers_till` (now equal to the cycle start and end); remove `cycles`; add `cycle_label` (string), `is_partial` (bool).
9. The Razorpay `description` must be **short, and must not contain a colon**. UPI apps truncate and mangle longer notes, as seen in a real test where the colon and a day went missing. Use e.g. `Monthly fees 17 Nov to 16 Dec` and `Part payment 17 Nov to 16 Dec`. Keep it under about 35 characters.

### 6.2 `GET /payments/student/{student_id}/fee-status` (extend)
Response:
```json
{
  "student_id": 13,
  "fee_type": "monthly",
  "fee_amount": 2500,
  "fee_paid_till": "2026-11-20",
  "next_due_date": "2026-11-21",
  "is_due": true,
  "can_pay": true,
  "cannot_pay_reason": null,
  "cycle_start": "2026-11-21",
  "cycle_end": "2026-12-20",
  "cycle_label": "21 Nov to 20 Dec 2026",
  "cycle_fee": 2500,
  "cycle_paid": 500,
  "cycle_balance": 2000,
  "allow_partial_payment": false,
  "min_partial_amount": 100
}
```
- `can_pay` per 3.4, with `cannot_pay_reason` like `"Fees are already paid until 20 Dec 2026"` when false.
- **Access:** the owning student, **and admins for any student** (use the existing role-check helper, e.g. `check_user_role`). Admins need this for the admin fee card. Everyone else gets 404.
- `cycle_label` format: `"{start:%d %b} to {end:%d %b %Y}"`, and if the years differ, `"{start:%d %b %Y} to {end:%d %b %Y}"`. Implement this as `cycle_label(start, end)` in `billing.py` with unit tests (same year, year rollover, leap-year end dates).

### 6.3 Admin switch endpoint (new)
`PATCH /student/{id}/partial-payment` with body `{"allow_partial_payment": true}`.
- **Admin only.** Enforce the role check properly (see section 9).
- Updates `students.allow_partial_payment` and `updated_at`, returns the new value.

### 6.4 Payment models (manual endpoints)
- `PaymentCreate`: add `record_only: bool = False`.
- `Payment` (response and history): add `cycle_start`, `cycle_end`, `cycle_fee`, and a computed `cycle_label` (null when cycle columns are null).
- Keep existing fields (including `isActive`, `payment_category`, etc.) unchanged.

### 6.5 Webhook: handle `payment.failed` (new)
- In addition to `payment.captured` and `order.paid`, handle `payment.failed`.
- From `payload.payment.entity` read `order_id`, `id`, `error_description`, `error_reason`, `error_code`.
- Look up the order. If unknown, log and return 200.
- If `last_failed_payment_id` already equals this payment id, return 200 without notifying (dedupe retries).
- Store `last_error` (description, fall back to reason), `last_error_at = now()`, `last_failed_payment_id`. **Do not change the order status.** The student can retry the same order.
- After the DB write, send failure notifications (section 8).
- Cancelling checkout produces no webhook, so there is no push for plain cancellation. That is intended.
- **Manual step for the project owner:** in the Razorpay dashboard (both Test and Live), edit the webhook and tick the `payment.failed` event.

### 6.6 Order status endpoint
`GET /payments/order/{id}/status`: add `last_error` to the response so the app can show the failure reason. Add it to the Dart model as nullable.

---

## 7. Backend: billing helpers to add (`billing.py`)
- `cycle_label(start, end)` as above.
- `current_cycle(fee_paid_till, date_of_joining, fee_type)` returning `(start, end)`, a thin wrapper over `coverage(..., cycles=1)`.
- Keep `fee_to_rupees`, `normalize_fee_type`, and `coverage` exactly as they are. Extend the existing unit tests; run them.

---

## 8. Push notifications (FCM)

Use the existing `fcm_service`. **First read how it works:** how device tokens are stored per user, how a send is made, whether invalid tokens are cleaned up, and how admins are identified (a role column or topic). If there is no "notify all admins" helper, add one: look up users with the admin role, collect their tokens, send, and let one failure not block the rest.

### 8.1 When
| Event | Student | Admins |
|---|---|---|
| Online payment settled (full or part) | yes | yes |
| Overpayment detected at settlement | no | yes |
| Online payment failed (`payment.failed`) | yes | yes |
| Manual payment recorded | yes, **only if `paid_on` is within the last 2 days or omitted** (avoids spamming for backfills) | no (the admin entering it already knows) |
| Manual correct or delete | no | no |

### 8.2 Text (adapt wording freely but keep the meaning)
- Student, full cycle paid: `Payment of ₹{amount} received for {cycle_label}. Fees paid till {fee_paid_till}.`
- Student, part payment: `₹{amount} received for {cycle_label}. ₹{balance} remaining.`
- Admin, success: `{student_name} paid ₹{amount} ({mode}), {Full | Part, ₹{balance} due}.`
- Admin, overpayment: `Overpayment: {student_name} paid ₹{amount}; cycle {cycle_label} was already fully paid. Review or refund.`
- Student, failure: `Payment failed: {last_error or "the bank declined it"}. If money was debited, your bank usually reverses it automatically.`
- Admin, failure: `Payment failed for {student_name}: {last_error}.`

### 8.3 Data payload
Include a `data` map: `type` (`payment_success`, `payment_failed`, or `payment_overpaid`), `student_id`, `order_id` when known. The app uses it to refresh.

### 8.4 Delivery rules
- Always after commit. Run in a FastAPI `BackgroundTasks` or an `asyncio` task so the webhook responds quickly.
- Never raise. Log failures.
- **Known limitation:** on Render's free tier the server can spin down, and a background task can be lost if the process restarts at that moment. The payment itself is already safe in the DB, and the app also polls status, so this is acceptable.
- A push for the same settlement must only ever be sent once. Rely on `apply_payment` running once per order (the idempotent path returns `already_paid` on retries, and callers must send nothing in that case).

### 8.5 Emails are **out of scope** for this task
Email receipts (planned later via Brevo's HTTP API, because Render free blocks SMTP ports) are deferred. Leave a clearly marked hook (a no-op function called after a successful settlement) and do nothing else.

---

## 9. Security prerequisite
The manual payment endpoints currently take `get_current_user` but **never check the role**. They now also move `fee_paid_till` and trigger notifications. Before this ships, enforce admin-only on: manual create, correct, delete, the partial-payment switch endpoint, and the admin access path of `fee-status`. Return 403 for non-admins. Verify that the existing role helper really reads the role from the DB and not from the client.

---

## 10. Flutter changes

### 10.1 Models and API (`checkout_models.dart`, `razorpay_api_service.dart`)
- `FeeStatus`: add `canPay`, `cannotPayReason`, `cycleStart`, `cycleEnd`, `cycleLabel`, `cycleFee`, `cyclePaid`, `cycleBalance`, `allowPartialPayment`, `minPartialAmount`. All dates are `yyyy-MM-dd` strings.
- `CheckoutOptions`: remove `cycles`; add `cycleLabel` and `isPartial`.
- `OrderStatus`: add nullable `lastError`.
- `startPayment({required int studentId, int? amount})`: send `amount` in the body **only when non-null**. Remove the `cycles` parameter everywhere (service, notifier, `PayFeesButton`).
- Payment history model (`Payment`): add `cycleStart`, `cycleEnd`, `cycleFee`, `cycleLabel`, all nullable. `PaymentCreate`: add `recordOnly` (default false).
- Add an admin API call for the switch: `PATCH /student/{id}/partial-payment`.
- `fee-status` should now work when called by an admin for any student.

### 10.2 Notifier (`online_payment_notifier.dart`)
- `pay({int? amount})` passes the amount to the API. Everything else stays (verify, poll, `feeStatusProvider` invalidation on success).
- On a start error (409 or 422), the existing `paymentErrorMessage` already shows the server `detail`. Keep that.
- When the polling or error path has a `lastError`, show it in the failure message.

### 10.3 Student profile `_FeesCard`
- **Stop using the stale `student` object for money fields.** Watch `feeStatusProvider(studentId)` and render from it: fee amount, frequency, **Paid Till**, cycle label, and a small progress line `Paid ₹{cyclePaid} of ₹{cycleFee}` with balance.
- Guard `student.id` being nullable at the top of the widget (copy it into a local variable and hide the pay section if null). The widget must be a `ConsumerWidget`.
- Pay section:
  - If `!canPay`: show a **disabled** Pay Fees button and the text `cannotPayReason`.
  - If `canPay` and **`allowPartialPayment` is false**: no amount field; button label `Pay ₹{cycleBalance}`; pays the full balance.
  - If `canPay` and **`allowPartialPayment` is true**: show a numeric `TextField` (digits only) **prefilled with `cycleBalance`**, helper text `Pay between ₹{minPartialAmount} and ₹{cycleBalance}`. Validate on the client: integer, within the range, or exactly the balance. The button passes that amount. (The server re-validates.) If the field is cleared, fall back to the full balance.
- `onPaid`: invalidate `feeStatusProvider(studentId)`, the payment history provider, and whatever provider feeds the student profile.

### 10.4 Admin student detail fee card
- Show cycle label, paid, balance (from `fee-status`).
- Add a `SwitchListTile` **"Allow part payment for this cycle"**, bound to `allowPartialPayment`, calling the PATCH endpoint, with optimistic update and rollback on error. Helper text: `Turns itself off when the cycle is fully paid.`
- Manual payment form: add the "Record only (don't affect due date)" checkbox, default off. Show the cycle balance as a hint, and show the server's 422 message if the amount exceeds it.

### 10.5 Payment history rows
- Show `cycleLabel` under each fee payment when present.
- Show a small "Part payment" chip when `cycleFee != null && amount < cycleFee`.
- After a **delete or correct** succeeds, show a snackbar: `Check this student's Paid Till date.`

### 10.6 FCM in the app (nice to have, only if token handling already exists)
When a foreground message of type `payment_success` or `payment_failed` arrives, invalidate `feeStatusProvider` for the given `student_id` and the payment history provider. Do not build a notification UI unless one already exists.

---

## 11. Phases (stop after each)

1. **Migration and billing.** Write `002_...sql`; add `cycle_label` and `current_cycle` with tests. No behavioural change yet.
2. **Backend core.** Shared `apply_payment`; rewrite `settle_order`; `/payments/start` guards and partial amount; extended `fee-status`; manual create, correct, and delete updates; admin switch endpoint; role checks (section 9). Verify with SQL and the checklist in section 12.
3. **Push notifications.** `payment.failed` webhook; success, failure, and overpayment pushes; admin notify helper.
4. **Flutter, student side.** Models, API, notifier, `_FeesCard`, history rows.
5. **Flutter, admin side.** Switch, cycle info, record-only checkbox, delete or correct reminder.
6. *(Later, not now)* Email receipts via Brevo; rollback of `fee_paid_till` on delete or correct (will use `cycle_start`, `cycle_end`, `cycle_fee` to recompute from the last fully paid cycle).

---

## 12. Test checklist
Use the dummy student with `fees = 2500` (the current test student has `fees = 1`, which makes partials impossible because of the minimum). Reset first: `update students set fee_paid_till = null, allow_partial_payment = false where id = <id>;` and clear test payments.

1. Full online payment of 2500: one payment row with cycle fields, `fee_paid_till = cycle_end`, push to student and admins, button disabled afterwards (`can_pay` false).
2. Partial disabled: start with `amount: 500` → 422 "Part payment is not enabled". Full still works.
3. Admin enables the switch, student pays 500: date does **not** move, balance 2000, push says remaining ₹2000. Student pays 2000: date moves, switch resets to false.
4. ₹1500 fee: 1000 then 500, same result.
5. Amount above the balance → 422; amount below the minimum → 422; amount equal to a balance smaller than the minimum → allowed.
6. Start while `fee_paid_till >= today` → 409.
7. Admin manual partial (switch off) is accepted; manual amount above the balance is rejected with a clear 422; `record_only` leaves the date and cycle sums untouched.
8. Webhook replay (send the same `payment.captured` twice) and verify + webhook race: exactly one payment row, exactly one push.
9. Overpayment: open checkout, record a manual cash payment completing the cycle, then finish the online payment. The payment is recorded, the admin gets the overpayment push, and `fee_paid_till` does not regress.
10. `payment.failed` event: `last_error` saved, one student push and one admin push, order stays `created`, a repeated delivery sends nothing new.
11. Non-admin calling manual create, correct, delete, or the switch → 403.
12. Cycle-label unit tests, including year rollover.
13. Run the existing `billing` tests; they must still pass.

---

## 13. Open assumptions (the agent should surface these in its current-state note if they turn out false)
- `MIN_PARTIAL_PAYMENT_RUPEES` default of 100 is a placeholder the owner may change.
- `fee_type` enum labels, `students.status` values, and the admin role mechanism are unverified.
- Render free tier cold starts can delay the first request, and background tasks can be lost on restart. Both are accepted for now.
