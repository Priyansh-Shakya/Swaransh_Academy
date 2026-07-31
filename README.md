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


# Image Buckets
| Feature        | Bucket             | Object name/path stored internally  | DB column holds                           |
| -------------- | ------------------ | ----------------------------------- | ----------------------------------------- |
| Student create | `student-photos`   | `students/{user_id}/{ts}_photo.jpg` | Full public URL in `students.image_url`   |
| Admission form | `admission-photos` | `admissions/{email}/{ts}_photo.jpg` | Full public URL in `admissions.image_url` |



TODO: 
1. Make Scholar_Number Read-Only Field for Admin as well.
2. Any backend "internal server error"  gives "No internet connection" on frontend.
3. MAKE A WHATSAPP LIKE UI - for multiple (sibling) profiles => Show all of them instead of asking scholar number.


TO CHECk:

1. Multiple Students with same email - User created -> Auth Link all sudents with that user_id : CHECKED
2. User Already exists -> Multiple students created with same email => Auto link all students with that user_id : CHECKED

Todo:
- Role select Screen:
  - Logo is small ... have blank space below admin...
  - use blank space , shift role cards down and make logo bigger.


1600 x 656 - mobile: best fit , desktop: good
1400x400 - Perfect on both
1400x500 - Again perfect
Note: all mobile verisons are tested on chrome with small mobile like window and not on actua; Phone!




TODO:
1 admin imges bucket
2 Apply for Certificate Feature - Payment Gated , Small Test Maybe.



TODO:
1 Send button should show streaming when waiting for message ,(dissable send button)
2 Markdown rendering
3 Initial chat of sargam shoudl include user's name if available!
4 Instead of using multiple DB calls in backend for determining role and then fetching some kind of info ... use joins if posisible