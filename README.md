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



-- Creates buckets if they don't exist
INSERT INTO storage.buckets (id, name, public)
VALUES 
  ('student-photos', 'student-photos', false),
  ('admission-photos', 'admission-photos', false),
  ('course-images', 'course-images', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Admins can upload student photos"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'student-photos'
  AND EXISTS (
    SELECT 1
    FROM public.users u
    WHERE u.user_id = auth.uid()
      AND u.role = 'admin'
  )
);

-- RLS policy: authenticated users can read student photos
CREATE POLICY "Auth users can read student photos"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'student-photos');

-- Same for admission photos
CREATE POLICY "Auth users can upload admission photos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'admission-photos');

CREATE POLICY "Auth users can read admission photos"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'admission-photos');

CREATE POLICY "Admins can update student photos"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'student-photos'
  AND EXISTS (
    SELECT 1
    FROM public.users u
    WHERE u.user_id = auth.uid()
      AND u.role = 'admin'
  )
)
WITH CHECK (
  bucket_id = 'student-photos'
  AND EXISTS (
    SELECT 1
    FROM public.users u
    WHERE u.user_id = auth.uid()
      AND u.role = 'admin'
  )
);

CREATE POLICY "Admins can delete student photos"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'student-photos'
  AND EXISTS (
    SELECT 1
    FROM public.users u
    WHERE u.user_id = auth.uid()
      AND u.role = 'admin'
  )
);

-- Course images are public
CREATE POLICY "Anyone can read course images"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'course-images');

CREATE POLICY "Admins can upload course images"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'course-images'
  AND EXISTS (
    SELECT 1
    FROM public.users u
    WHERE u.user_id = auth.uid()
      AND u.role = 'admin'
  )
);