"""Service for Profile operations"""

from uuid import UUID

from app.features.profile import model, repository
from app.features.student import model as studentModel


async def get_user_profile(user_id: UUID, db) -> model.UserProfile:
    """Get user profile"""
    row = await db.fetchrow(repository.get_user_profile_query, user_id)
    if not row:
        raise ValueError(f"User {user_id} not found")
    return model.UserProfile(**dict(row))


async def get_student_profile(student_id: int, db) -> studentModel.StudentFullRead:
    """Get student profile by student ID"""
    row = await db.fetchrow(repository.get_student_profile_query, student_id)
    if not row:
        raise ValueError(f"Student {student_id} not found")
    return studentModel.StudentFullRead(**dict(row))

async def get_my_profile(user, db) -> dict:
    """
    Get current user's profile.

    Returns:
        {"type": "student", "data": [StudentFullRead, ...]}  # 1+ linked students
        {"type": "user", "data": UserProfile}                # no student link
    """
    user_id = user['id']

    student_rows = await db.fetch(repository.get_student_by_user_id_query, user_id)
    if student_rows:
        students = [studentModel.StudentFullRead(**dict(row)) for row in student_rows]
        print("Number of profiles:", len(students))
        return {"type": "student", "data": students}

    user_row = await db.fetchrow(repository.get_user_profile_query, user_id)
    if user_row:
        return {"type": "user", "data": model.UserProfile(**dict(user_row))}

    raise ValueError(f"Profile for user {user_id} not found")