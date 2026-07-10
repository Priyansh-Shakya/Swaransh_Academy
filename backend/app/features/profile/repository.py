"""Repository for Profile data access"""

# Get student profile by student ID
get_student_profile_query = """
SELECT * FROM students WHERE id = $1;
"""

# Get user profile by user ID
get_user_profile_query = """
SELECT * FROM users WHERE user_id = $1;
"""

# Get student profile by user ID (linked student)
get_student_by_user_id_query = """
SELECT * FROM students WHERE user_id = $1;
"""
