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



```python
raise HTTPException(
    status_code=409,
    detail={
        "code": "MULTIPLE_STUDENTS_FOUND",
        "message": "Multiple students share this email."
    }
)
```


TODO: 
1. Make Scholar_Number Read-Only Field for Admin as well.
2. Any backend "internal server error"  gives "No internet connection" on frontend.
3. MAKE A WHATSAPP LIKE UI - for multiple (sibling) profiles => Show all of them instead of asking scholar number.


TO CHECk:

1. Multiple Students with same email - User created -> Auth Link all sudents with that user_id : CHECKED
2. User Already exists -> Multiple students created with same email => Auto link all students with that user_id : CHECKED