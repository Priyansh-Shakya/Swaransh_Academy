"""Repository for Courses data access"""

# Create course
create_course_query = """
INSERT INTO courses (course_name, duration, fees, mode, tag, maps_to_department, maps_to_subject, image_url)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
RETURNING *;
"""

# Get course by ID
get_course_by_id_query = """
SELECT * FROM courses WHERE id = $1;
"""

# Get all courses
get_all_courses_query = """
SELECT * FROM courses ORDER BY created_at DESC;
"""

# Update course
update_course_query = """
UPDATE courses SET
    course_name = COALESCE($1, course_name),
    duration = COALESCE($2, duration),
    fees = COALESCE($3, fees),
    mode = COALESCE($4, mode),
    tag = COALESCE($5, tag),
    maps_to_department = COALESCE($6, maps_to_department),
    maps_to_subject = COALESCE($7, maps_to_subject),
    image_url = COALESCE($8, image_url),
    updated_at = now()
WHERE id = $9
RETURNING *;
"""

# Delete course
delete_course_query = """
DELETE FROM courses WHERE id = $1;
"""
