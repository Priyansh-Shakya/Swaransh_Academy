INSERT INTO storage.buckets (id, name, public)
VALUES
  ('student-photos', 'student-photos', false),
  ('admission-photos', 'admission-photos', true),
  ('course-images', 'course-images', true)
ON CONFLICT (id) DO NOTHING;


--* RLS POLICIES For Buckets


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
-- Public read for pending admission photos (admin needs to view during review)
CREATE POLICY "Public can read pending admission photos"
ON storage.objects FOR SELECT
TO public
USING (
  bucket_id = 'admission-photos'
  AND (storage.foldername(name))[1] = 'pending'
);

-- Anon/public can upload (pre-auth form submission)
CREATE POLICY "Anyone can upload admission photos"
ON storage.objects FOR INSERT
TO public
WITH CHECK (
  bucket_id = 'admission-photos'
  AND (storage.foldername(name))[1] = 'pending'
);

-- Only authenticated (admin) can delete — rejection path
CREATE POLICY "Authenticated can delete admission photos"
ON storage.objects FOR DELETE
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