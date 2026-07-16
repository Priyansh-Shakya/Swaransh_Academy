-- ============================================
-- USERS
-- ============================================

INSERT INTO public.users (user_id, user_name, role, email, fcm_token)
VALUES
('cd0d243a-cc20-48e9-b1db-d9d2cb15d5fb', 'Kabir Khan', 'student', 'kabir@gmail.com', NULL),

('370577e7-066b-4c95-a510-44e478b89930', 'Sneha Mishra', 'student', 'sneha@gmail.com', NULL),

('d03d5ae6-3199-4797-9b6b-3a21d11e7dca', 'Vivaan Patel', 'guest', 'vivaan@gmail.com', NULL);


-- ============================================
-- COURSES
-- ============================================

INSERT INTO public.courses
(
    course_name,
    duration,
    fees,
    mode,
    tag,
    maps_to_department,
    maps_to_subject,
    image_url
)
VALUES

(
'Beginner Vocal Music',
'6 Months',
12000,
'Offline',
'Vocal',
'Music',
'Hindustani Classical',
'https://picsum.photos/400?1'
),

(
'Advanced Vocal Music',
'1 Year',
24000,
'Offline',
'Vocal',
'Music',
'Hindustani Classical',
'https://picsum.photos/400?2'
),

(
'Keyboard Essentials',
'8 Months',
18000,
'Hybrid',
'Instrumental',
'Music',
'Keyboard',
'https://picsum.photos/400?3'
),

(
'Tabla Mastery',
'1 Year',
22000,
'Offline',
'Instrumental',
'Music',
'Tabla',
'https://picsum.photos/400?4'
),

(
'Kathak Foundation',
'9 Months',
20000,
'Offline',
'Vocal',
'Dance',
'Kathak',
'https://picsum.photos/400?5'
),

(
'Bollywood Dance',
'4 Months',
10000,
'Offline',
'Vocal',
'Dance',
'Bollywood Dance',
'https://picsum.photos/400?6'
),

(
'Acting for Beginners',
'6 Months',
18000,
'Offline',
'Vocal',
'Acting',
'Stage Acting',
'https://picsum.photos/400?7'
),

(
'Music Video Production',
'1 Year',
35000,
'Hybrid',
'Instrumental',
'Music_Video_Production',
'Video Editing',
'https://picsum.photos/400?8'
);


-- ============================================
-- STUDENTS
-- ============================================

INSERT INTO public.students
(
    user_id,
    name,
    admission_type,
    learning_mode,
    department,
    batch,
    education_qualification,
    admission_status,
    status,
    start_time,
    end_time,
    subject,
    courses,
    dob,
    father_name,
    gender,
    address,
    religion,
    caste,
    scholar_no,
    date_of_joining,
    contact,
    email,
    fees,
    fee_type,
    fee_paid_till,
    image_url
)
VALUES

(
'22222222-2222-2222-2222-222222222222',
'Aarav Verma',
'Regular',
'Offline',
'Music',
'Morning',
'High_School',
'Approved',
'active',
'2025-07-01 09:00:00+05:30',
'2025-07-01 10:30:00+05:30',
'Hindustani Classical',
ARRAY['Beginner Vocal Music'],
'2008-03-15',
'Rajesh Verma',
'male',
'Bhopal',
'Hindu',
'General',
'SV001',
'2025-07-01',
'9876543210',
'aarav@gmail.com',
12000,
'Monthly',
'2025-07-31',
NULL
),

(
'33333333-3333-3333-3333-333333333333',
'Ananya Gupta',
'Regular',
'Offline',
'Dance',
'Evening',
'Bachelors',
'Approved',
'active',
'2025-07-01 17:00:00+05:30',
'2025-07-01 18:30:00+05:30',
'Kathak',
ARRAY['Kathak Foundation'],
'2003-09-11',
'Sanjay Gupta',
'female',
'Indore',
'Hindu',
'General',
'SV002',
'2025-07-01',
'9876543211',
'ananya@gmail.com',
20000,
'Quarterly',
'2025-09-30',
NULL
),

(
'44444444-4444-4444-4444-444444444444',
'Rohan Singh',
'Band_Training',
'Hybrid',
'Music',
'Morning',
'High_School',
'Approved',
'pending_payment',
'2025-07-01 10:00:00+05:30',
'2025-07-01 11:30:00+05:30',
'Keyboard',
ARRAY['Keyboard Essentials'],
'2007-11-19',
'Amit Singh',
'male',
'Sehore',
'Hindu',
'OBC',
'SV003',
'2025-07-01',
'9876543212',
'rohan@gmail.com',
18000,
'Monthly',
NULL,
NULL
),

(
'55555555-5555-5555-5555-555555555555',
'Meera Joshi',
'Regular',
'Offline',
'Music',
'Evening',
'Masters',
'Approved',
'active',
'2025-07-01 18:00:00+05:30',
'2025-07-01 19:30:00+05:30',
'Tabla',
ARRAY['Tabla Mastery'],
'1999-05-28',
'Mahesh Joshi',
'female',
'Bhopal',
'Hindu',
'General',
'SV004',
'2025-07-01',
'9876543213',
'meera@gmail.com',
22000,
'Half_Yearly',
'2025-12-31',
NULL
),

(
'66666666-6666-6666-6666-666666666666',
'Kabir Khan',
'Summer_Camp',
'Offline',
'Acting',
'Morning',
'Bachelors',
'Approved',
'active',
'2025-07-10 09:00:00+05:30',
'2025-07-10 11:00:00+05:30',
'Stage Acting',
ARRAY['Acting for Beginners'],
'2002-12-05',
'Imran Khan',
'male',
'Bhopal',
'Muslim',
NULL,
'SV005',
'2025-07-10',
'9876543214',
'kabir@gmail.com',
18000,
'Monthly',
'2025-07-31',
NULL
),

(
'77777777-7777-7777-7777-777777777777',
'Sneha Mishra',
'Regular',
'Hybrid',
'Music_Video_Production',
'Evening',
'Masters',
'Approved',
'active',
'2025-07-15 18:30:00+05:30',
'2025-07-15 20:00:00+05:30',
'Video Editing',
ARRAY['Music Video Production'],
'2000-01-17',
'Anil Mishra',
'female',
'Jabalpur',
'Hindu',
'General',
'SV006',
'2025-07-15',
'9876543215',
'sneha@gmail.com',
35000,
'Yearly',
'2026-07-14',
NULL
),

(
NULL,
'Rahul Tiwari',
'Custom',
'Online',
'Other',
'Morning',
'High_School',
'Pending',
'inactive',
'2025-08-01 08:00:00+05:30',
'2025-08-01 09:00:00+05:30',
'Public Speaking',
ARRAY['Custom Course'],
'2009-04-20',
'Vijay Tiwari',
'male',
'Vidisha',
'Hindu',
NULL,
'SV007',
'2025-08-01',
'9876543216',
'rahul@gmail.com',
8000,
'Monthly',
NULL,
NULL
),

(
'88888888-8888-8888-8888-888888888888',
'Vivaan Patel',
'Regular',
'Offline',
'Dance',
'Morning',
'Primary_School',
'Approved',
'active',
'2025-07-20 09:00:00+05:30',
'2025-07-20 10:00:00+05:30',
'Bollywood Dance',
ARRAY['Bollywood Dance'],
'2013-08-09',
'Rakesh Patel',
'male',
'Ujjain',
'Hindu',
'General',
'SV008',
'2025-07-20',
'9876543217',
'vivaan@gmail.com',
10000,
'Quarterly',
'2025-09-30',
NULL
);


-- ============================================
-- ADMISSIONS
-- ============================================

INSERT INTO public.admissions
(
    user_id,
    status,
    name,
    dob,
    gender,
    father_name,
    education_qualification,
    contact,
    email,
    address,
    religion,
    caste,
    admission_type,
    learning_mode,
    department,
    batch,
    start_time,
    end_time,
    subject,
    courses,
    fees,
    fee_type
)
VALUES

(
'11111111-1111-1111-1111-111111111111',
'Pending',
'Aditi Sharma',
'2012-02-14',
'female',
'Deepak Sharma',
'Primary_School',
'9876500001',
'aditi@gmail.com',
'Bhopal',
'Hindu',
'General',
'Regular',
'Offline',
'Dance',
'Morning',
'2025-08-01 09:00:00+05:30',
'2025-08-01 10:00:00+05:30',
'Kathak',
ARRAY['Kathak Foundation'],
20000,
'Quarterly'
),

(
'33333333-3333-3333-3333-333333333333',
'Pending',
'Arjun Yadav',
'2007-06-22',
'male',
'Suresh Yadav',
'High_School',
'9876500002',
'arjun@gmail.com',
'Bhopal',
'Hindu',
'OBC',
'Regular',
'Offline',
'Music',
'Morning',
'2025-08-01 09:00:00+05:30',
'2025-08-01 10:30:00+05:30',
'Hindustani Classical',
ARRAY['Beginner Vocal Music'],
12000,
'Monthly'
),

(
'11111111-1111-1111-1111-111111111111',
'Approved',
'Fatima Ali',
'2005-01-30',
'female',
'Aslam Ali',
'Bachelors',
'9876500003',
'fatima@gmail.com',
'Indore',
'Muslim',
NULL,
'Regular',
'Hybrid',
'Music_Video_Production',
'Evening',
'2025-08-05 18:00:00+05:30',
'2025-08-05 20:00:00+05:30',
'Video Editing',
ARRAY['Music Video Production'],
35000,
'Yearly'
),

(
'66666666-6666-6666-6666-666666666666',
'Declined',
'Karan Jain',
'2008-10-09',
'male',
'Manoj Jain',
'High_School',
'9876500004',
'karan@gmail.com',
'Sagar',
'Jain',
NULL,
'Summer_Camp',
'Offline',
'Acting',
'Morning',
'2025-08-10 09:00:00+05:30',
'2025-08-10 11:00:00+05:30',
'Stage Acting',
ARRAY['Acting for Beginners'],
18000,
'Monthly'
),

(
'88888888-8888-8888-8888-888888888888',
'Pending',
'Neha Patel',
'2011-11-18',
'female',
'Ramesh Patel',
'Primary_School',
'9876500005',
'neha@gmail.com',
'Ujjain',
'Hindu',
'General',
'Regular',
'Offline',
'Dance',
'Evening',
'2025-08-15 17:00:00+05:30',
'2025-08-15 18:30:00+05:30',
'Bollywood Dance',
ARRAY['Bollywood Dance'],
10000,
'Quarterly'
);


-- ============================================
-- PAYMENTS
-- Assumes students.id = 1..8
-- ============================================

INSERT INTO public.payment
(
    student_id,
    payment_type,
    amount,
    mode,
    txn_ref,
    paid_on,
    status,
    superseded_by
)
VALUES

(
1,
'admission',
12000,
'UPI',
'UPI-100001',
'2025-07-01 09:15:00+05:30',
'active',
NULL
),

(
2,
'quarterly',
20000,
'Cash',
NULL,
'2025-07-02 18:10:00+05:30',
'active',
NULL
),

(
3,
'monthly',
1500,
'Card',
'CARD-200001',
'2025-07-03 10:25:00+05:30',
'active',
NULL
),

(
4,
'half_yearly',
22000,
'Bank_Transfer',
'BANK-300001',
'2025-07-04 19:10:00+05:30',
'active',
NULL
),

(
5,
'monthly',
18000,
'UPI',
'UPI-100005',
'2025-07-05 09:45:00+05:30',
'active',
NULL
),

(
6,
'yearly',
35000,
'Bank_Transfer',
'BANK-600001',
'2025-07-06 18:30:00+05:30',
'active',
NULL
),

(
7,
'monthly',
8000,
'Cash',
NULL,
'2025-07-07 08:20:00+05:30',
'active',
NULL
),

(
8,
'quarterly',
10000,
'UPI',
'UPI-100008',
'2025-07-08 09:10:00+05:30',
'active',
NULL
);



-- ==========================================================
-- Example of correcting a payment (Student 3)
-- Payment id 9 supersedes payment id 3
-- ==========================================================

INSERT INTO public.payment
(
    student_id,
    payment_type,
    amount,
    mode,
    txn_ref,
    paid_on,
    status,
    superseded_by
)
VALUES
(
3,
'monthly',
18000,
'UPI',
'UPI-CORRECT-003',
'2025-07-10 11:00:00+05:30',
'active',
NULL
);

UPDATE public.payment
SET
    status = 'superseded',
    superseded_by = 9
WHERE id = 3;



-- ==========================================================
-- Another correction (Student 5)
-- Payment id 10 supersedes payment id 5
-- ==========================================================

INSERT INTO public.payment
(
    student_id,
    payment_type,
    amount,
    mode,
    txn_ref,
    paid_on,
    status,
    superseded_by
)
VALUES
(
5,
'monthly',
18500,
'Card',
'CARD-CORRECT-005',
'2025-07-11 14:20:00+05:30',
'active',
NULL
);

UPDATE public.payment
SET
    status = 'superseded',
    superseded_by = 10
WHERE id = 5;