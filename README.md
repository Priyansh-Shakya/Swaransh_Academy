Initial Commit

```dart
// VERY VERY IMPORTANT
In sign in /up auth flow , go router's redirect plays an important role , it is the thing which pushes to home screen again and again.
navitagion/router/app_router.dart
```

```dart
For an online payment flow, the usual architecture is:

Student initiates payment.
Gateway (e.g. Razorpay/Stripe) completes payment.
Your backend verifies the gateway signature.
Backend inserts the payment (often using the service role, bypassing RLS).

In that design, students never insert directly into the payments table. They call an API, and only verified payments are recorded.
```



