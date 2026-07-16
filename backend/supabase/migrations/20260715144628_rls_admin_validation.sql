
--* HELPER FUNCTION which cheks if user is authenticated and admin . 
CREATE FUNCTION is_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
AS $$
SELECT EXISTS (
    SELECT 1
    FROM users
    WHERE user_id = auth.uid()
      AND role = 'admin'
);
$$;



--* Enable RLS for tables
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE admissions  ENABLE ROW LEVEL SECURITY;
ALTER TABLE students ENABLE ROW LEVEL SECURITY;

--* Create Policies


-- Courses
CREATE POLICY "anyone can read courses"
ON courses
FOR SELECT
TO public
USING(true);

CREATE POLICY "admin course insert only"
ON courses
FOR insert
TO authenticated
WITH CHECK(
    is_admin()
);


-- Users

CREATE POLICY "users can read their own profile"
ON users
FOR SELECT
TO authenticated
USING (
    user_id = auth.uid()
);

CREATE POLICY "users can create their own profile"
ON users
FOR INSERT
TO authenticated
WITH CHECK (
    user_id = auth.uid()
);

CREATE POLICY "users can update their own profile"
ON users
FOR UPDATE
TO authenticated
USING (
    user_id = auth.uid()
)
WITH CHECK (
    user_id = auth.uid()
);

-- No DELETE policy.
-- With RLS enabled, authenticated users cannot delete rows from the users table.
-- Account deletion (if supported) should be handled via your backend/service role.



-- Students
CREATE POLICY "students and admins can read students"
ON students
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM users u
        WHERE u.user_id = auth.uid()
          AND u.role IN ('student', 'admin')
    )
);

CREATE POLICY "admin can insert students"
ON students
FOR INSERT
TO authenticated
WITH CHECK (
    is_admin()
);

CREATE POLICY "admin can update students"
ON students
FOR UPDATE
TO authenticated
USING (
    is_admin()
)
WITH CHECK (
    is_admin()
);

CREATE POLICY "admin can delete students"
ON students
FOR DELETE
TO authenticated
USING (
    is_admin()
);

--- SKIPING PAYMENT TABLE
--! Because:
--For an online payment flow, the usual architecture is:
--Student initiates payment.
--Gateway (e.g. Razorpay/Stripe) completes payment.
--Your backend verifies the gateway signature.
--Backend inserts the payment (often using the service role, bypassing RLS).
--In that design, students never insert directly into the payments table. They call an API, and only verified payments are recorded.


-- Admissions

CREATE POLICY "users can create their own admission"
ON admissions
FOR INSERT
TO authenticated
WITH CHECK (
    user_id = auth.uid()
);

CREATE POLICY "owner and admin can read admissions"
ON admissions
FOR SELECT
TO authenticated
USING (
    user_id = auth.uid()
    OR is_admin()
);

CREATE POLICY "admin can update admissions"
ON admissions
FOR UPDATE
TO authenticated
USING (
    is_admin()
)
WITH CHECK (
    is_admin()
);


-- No DELETE policy.
-- Approval/Decline should be performed by an admin endpoint that updates the status.
-- Cleanup (if desired) can later be handled by a scheduled job, not an RLS policy.