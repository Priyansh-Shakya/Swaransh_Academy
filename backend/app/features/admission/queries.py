
create_addmision = """
INSERT INTO admissions (
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
VALUES (
    $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,
    $11,$12,$13,$14,$15,$16,$17,$18,$19,$20
)
RETURNING *;
"""