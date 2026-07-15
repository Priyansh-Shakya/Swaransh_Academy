"""Repository for Student data access"""

# Create student record
create_student_query = """
INSERT INTO students (
    user_id, name, admission_type, learning_mode, department, batch,
    education_qualification, admission_status, status, start_time, end_time,
    subject, courses, dob, father_name, gender, address, religion, caste,
    date_of_joining, contact, email, fees, fee_type, image_url
)
VALUES (
    $1, $2, $3, $4, $5, $6, $7, $8, $9, $10,
    $11, $12, $13, $14, $15, $16, $17, $18,
    $19, $20, $21, $22, $23, $24, $25
)
RETURNING *;
"""

# Get student by ID
get_student_by_id_query = """
SELECT * FROM students WHERE id = $1;
"""

# Get all students
get_all_students_query = """
SELECT * FROM students;
"""

# Update student
update_student_query = """
UPDATE students SET
    user_id = COALESCE($1, user_id),
    name = COALESCE($2, name),
    admission_type = COALESCE($3, admission_type),
    learning_mode = COALESCE($4, learning_mode),
    department = COALESCE($5, department),
    batch = COALESCE($6, batch),
    education_qualification = COALESCE($7, education_qualification),
    admission_status = COALESCE($8, admission_status),
    status = COALESCE($9, status),
    start_time = COALESCE($10, start_time),
    end_time = COALESCE($11, end_time),
    subject = COALESCE($12, subject),
    courses = COALESCE($13, courses),
    dob = COALESCE($14, dob),
    father_name = COALESCE($15, father_name),
    gender = COALESCE($16, gender),
    address = COALESCE($17, address),
    religion = COALESCE($18, religion),
    caste = COALESCE($19, caste),
    contact = COALESCE($20, contact),
    email = COALESCE($21, email),
    fees = COALESCE($22, fees),
    fee_type = COALESCE($23, fee_type),
    fee_paid_till = COALESCE($24, fee_paid_till),
    image_url = COALESCE($25, image_url),
    updated_at = now()
WHERE id = $26
RETURNING *;
"""
#! WE WERE DEELING WITH SCHOLAR_NO NOT UPDATING ISSUE

# Delete student
delete_student_query = """
DELETE FROM students WHERE id = $1;
"""

# Get students with filters
get_students_filtered_query = """
SELECT * FROM students
WHERE (
    ($1::department IS NULL OR department = $1) AND
    ($2::admission_type IS NULL OR admission_type = $2) AND
    ($3::learning_mode IS NULL OR learning_mode = $3) AND
    ($4::fee_type IS NULL OR fee_type = $4) AND
    ($5::batch IS NULL OR batch = $5) AND
    ($6::float IS NULL OR fees >= $6) AND
    ($7::float IS NULL OR fees <= $7) AND
    ($8::date IS NULL OR date_of_joining >= $8) AND
    ($9::date IS NULL OR date_of_joining <= $9) AND
    ($10::text IS NULL OR name ILIKE '%' || $10 || '%' OR email ILIKE '%' || $10 || '%')
)
ORDER BY created_at DESC;
"""
