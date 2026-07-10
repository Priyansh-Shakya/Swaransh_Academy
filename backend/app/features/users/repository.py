"""Repository for User data access"""

# SQL Queries for User operations
create_user_query = """
INSERT INTO users (user_id, user_name, role, email, fcm_token)
VALUES ($1, $2, $3, $4, $5)
RETURNING *;
"""

get_user_by_id_query = """
SELECT * FROM users WHERE user_id = $1;
"""

get_user_by_email_query = """
SELECT * FROM users WHERE email = $1;
"""

update_user_fcm_token_query = """
UPDATE users SET fcm_token = $1 WHERE user_id = $2
RETURNING *;
"""

get_student_by_email_query = """
SELECT * FROM students WHERE email = $1;
"""

link_user_to_student_query = """
UPDATE students SET user_id = $1 WHERE id = $2
RETURNING *;
"""
