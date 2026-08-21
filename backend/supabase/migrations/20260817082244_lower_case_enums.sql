-- ============================================================
-- Normalize public enum values to lowercase snake_case
-- ============================================================

-- department
-- 'Music' was already renamed to 'music', so only rename the
-- remaining values.
ALTER TYPE public.department
RENAME VALUE 'Dance' TO 'dance';

ALTER TYPE public.department
RENAME VALUE 'Acting' TO 'acting';

ALTER TYPE public.department
RENAME VALUE 'Music_Video_Production'
TO 'music_video_production';

ALTER TYPE public.department
RENAME VALUE 'Other' TO 'other';


-- admission_status
ALTER TYPE public.admission_status
RENAME VALUE 'Pending' TO 'pending';

ALTER TYPE public.admission_status
RENAME VALUE 'Approved' TO 'approved';

ALTER TYPE public.admission_status
RENAME VALUE 'Declined' TO 'declined';


-- admission_type
ALTER TYPE public.admission_type
RENAME VALUE 'Regular' TO 'regular';

ALTER TYPE public.admission_type
RENAME VALUE 'Band_Training' TO 'band_training';

ALTER TYPE public.admission_type
RENAME VALUE 'Summer_Camp' TO 'summer_camp';

ALTER TYPE public.admission_type
RENAME VALUE 'Custom' TO 'custom';


-- batch
ALTER TYPE public.batch
RENAME VALUE 'Morning' TO 'morning';

ALTER TYPE public.batch
RENAME VALUE 'Evening' TO 'evening';


-- course_tag
ALTER TYPE public.course_tag
RENAME VALUE 'Vocal' TO 'vocal';

ALTER TYPE public.course_tag
RENAME VALUE 'Instrumental' TO 'instrumental';


-- education_qualification
ALTER TYPE public.education_qualification
RENAME VALUE 'Primary_School' TO 'primary_school';

ALTER TYPE public.education_qualification
RENAME VALUE 'High_School' TO 'high_school';

ALTER TYPE public.education_qualification
RENAME VALUE 'Bachelors' TO 'bachelors';

ALTER TYPE public.education_qualification
RENAME VALUE 'Masters' TO 'masters';


-- fee_type
ALTER TYPE public.fee_type
RENAME VALUE 'Monthly' TO 'monthly';

ALTER TYPE public.fee_type
RENAME VALUE 'Quarterly' TO 'quarterly';

ALTER TYPE public.fee_type
RENAME VALUE 'Half_Yearly' TO 'half_yearly';

ALTER TYPE public.fee_type
RENAME VALUE 'Yearly' TO 'yearly';


-- learning_mode
ALTER TYPE public.learning_mode
RENAME VALUE 'Online' TO 'online';

ALTER TYPE public.learning_mode
RENAME VALUE 'Offline' TO 'offline';

ALTER TYPE public.learning_mode
RENAME VALUE 'Hybrid' TO 'hybrid';


-- payment_mode
ALTER TYPE public.payment_mode
RENAME VALUE 'Cash' TO 'cash';

ALTER TYPE public.payment_mode
RENAME VALUE 'UPI' TO 'upi';

ALTER TYPE public.payment_mode
RENAME VALUE 'Card' TO 'card';

ALTER TYPE public.payment_mode
RENAME VALUE 'Bank_Transfer' TO 'bank_transfer';

ALTER TYPE public.payment_mode
RENAME VALUE 'Other' TO 'other';


-- student_gender
ALTER TYPE public.student_gender
RENAME VALUE 'nonbinary' TO 'non_binary';