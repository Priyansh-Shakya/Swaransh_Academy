DO $$
DECLARE
    r RECORD;
    -- Define all (schema, enum, old_val, new_val) mappings you want to ensure
    v_renames TEXT[][] := ARRAY[
        -- department
        ARRAY['public', 'department', 'Music', 'music'],
        ARRAY['public', 'department', 'Dance', 'dance'],
        ARRAY['public', 'department', 'Acting', 'acting'],
        ARRAY['public', 'department', 'Music Video Production', 'music_video_production'],
        ARRAY['public', 'department', 'Other', 'other'],

        -- admission_status
        ARRAY['public', 'admission_status', 'Pending', 'pending'],
        ARRAY['public', 'admission_status', 'Approved', 'approved'],
        ARRAY['public', 'admission_status', 'Declined', 'declined'],

        -- batch
        ARRAY['public', 'batch', 'Morning', 'morning'],
        ARRAY['public', 'batch', 'Evening', 'evening'],

        -- course_tag
        ARRAY['public', 'course_tag', 'Vocal', 'vocal'],
        ARRAY['public', 'course_tag', 'Instrumental', 'instrumental'],

        -- student_gender
        ARRAY['public', 'student_gender', 'Male', 'male'],
        ARRAY['public', 'student_gender', 'Female', 'female'],
        ARRAY['public', 'student_gender', 'Nonbinary', 'nonbinary'],

        -- student_status
        ARRAY['public', 'student_status', 'Pending Payment', 'pending_payment'],
        ARRAY['public', 'student_status', 'Active', 'active'],
        ARRAY['public', 'student_status', 'Inactive', 'inactive'],

        -- user_role
        ARRAY['public', 'user_role', 'Guest', 'guest'],
        ARRAY['public', 'user_role', 'Student', 'student'],
        ARRAY['public', 'user_role', 'Admin', 'admin']
    ];
    elem TEXT[];
BEGIN
    FOREACH elem SLICE 1 IN ARRAY v_renames
    LOOP
        -- Check if the old (capitalized) value exists for this enum
        IF EXISTS (
            SELECT 1
            FROM pg_enum e
            JOIN pg_type t ON t.oid = e.enumtypid
            JOIN pg_namespace n ON n.oid = t.typnamespace
            WHERE n.nspname = elem[1]
              AND t.typname = elem[2]
              AND e.enumlabel = elem[3]
        ) THEN
            EXECUTE format(
                'ALTER TYPE %I.%I RENAME VALUE %L TO %L',
                elem[1], elem[2], elem[3], elem[4]
            );
            RAISE NOTICE 'Renamed %.% from % to %', elem[1], elem[2], elem[3], elem[4];
        END IF;
    END LOOP;
END $$;

-- --! BELOW CODE IS FOR LOCAL SUPABASE PROJECT ONLY , CHANGING ENUMS TO LOWERCASE FOR LOCAL PROJECT

-- -- admission_type
-- ALTER TYPE public.admission_type RENAME VALUE 'Regular' TO 'regular';
-- ALTER TYPE public.admission_type RENAME VALUE 'Band_Training' TO 'band_training';
-- ALTER TYPE public.admission_type RENAME VALUE 'Summer_Camp' TO 'summer_camp';
-- ALTER TYPE public.admission_type RENAME VALUE 'Custom' TO 'custom';

-- -- learning_mode
-- ALTER TYPE public.learning_mode RENAME VALUE 'Online' TO 'online';
-- ALTER TYPE public.learning_mode RENAME VALUE 'Offline' TO 'offline';
-- ALTER TYPE public.learning_mode RENAME VALUE 'Hybrid' TO 'hybrid';

-- -- department
-- ALTER TYPE public.department RENAME VALUE 'Music' TO 'music';
-- ALTER TYPE public.department RENAME VALUE 'Dance' TO 'dance';
-- ALTER TYPE public.department RENAME VALUE 'Acting' TO 'acting';
-- ALTER TYPE public.department RENAME VALUE 'Music_Video_Production' TO 'music_video_production';
-- ALTER TYPE public.department RENAME VALUE 'Other' TO 'other';

-- -- course_tag
-- ALTER TYPE public.course_tag RENAME VALUE 'Vocal' TO 'vocal';
-- ALTER TYPE public.course_tag RENAME VALUE 'Instrumental' TO 'instrumental';

-- -- batch
-- ALTER TYPE public.batch RENAME VALUE 'Morning' TO 'morning';
-- ALTER TYPE public.batch RENAME VALUE 'Evening' TO 'evening';

-- -- education_qualification
-- ALTER TYPE public.education_qualification RENAME VALUE 'Primary_School' TO 'primary_school';
-- ALTER TYPE public.education_qualification RENAME VALUE 'High_School' TO 'high_school';
-- ALTER TYPE public.education_qualification RENAME VALUE 'Bachelors' TO 'bachelors';
-- ALTER TYPE public.education_qualification RENAME VALUE 'Masters' TO 'masters';

-- -- fee_type
-- ALTER TYPE public.fee_type RENAME VALUE 'Monthly' TO 'monthly';
-- ALTER TYPE public.fee_type RENAME VALUE 'Quarterly' TO 'quarterly';
-- ALTER TYPE public.fee_type RENAME VALUE 'Half_Yearly' TO 'half_yearly';
-- ALTER TYPE public.fee_type RENAME VALUE 'Yearly' TO 'yearly';

-- -- admission_status
-- ALTER TYPE public.admission_status RENAME VALUE 'Pending' TO 'pending';
-- ALTER TYPE public.admission_status RENAME VALUE 'Approved' TO 'approved';
-- ALTER TYPE public.admission_status RENAME VALUE 'Declined' TO 'declined';

-- -- payment_mode
-- ALTER TYPE public.payment_mode RENAME VALUE 'Cash' TO 'cash';
-- ALTER TYPE public.payment_mode RENAME VALUE 'UPI' TO 'upi';
-- ALTER TYPE public.payment_mode RENAME VALUE 'Card' TO 'card';
-- ALTER TYPE public.payment_mode RENAME VALUE 'Bank_Transfer' TO 'bank_transfer';
-- ALTER TYPE public.payment_mode RENAME VALUE 'Other' TO 'other';