"""Service for Profile operations"""

from typing import Optional, Union
from uuid import UUID

from app.features.profile import model, repository


async def get_user_profile(user_id: UUID, db) -> model.UserProfile:
    """Get user profile"""
    row = await db.fetchrow(repository.get_user_profile_query, user_id)
    if not row:
        raise ValueError(f"User {user_id} not found")
    return model.UserProfile(**dict(row))


async def get_student_profile(student_id: int, db) -> model.StudentProfileFull:
    """Get student profile by student ID"""
    row = await db.fetchrow(repository.get_student_profile_query, student_id)
    if not row:
        raise ValueError(f"Student {student_id} not found")
    return model.StudentProfileFull(**dict(row))


async def get_my_profile(
    user_id: UUID, db
) -> Optional[Union[model.UserProfile, model.StudentProfileFull]]:
    """
    Get current user's profile.
    
    If user is linked to a student, return student profile.
    Otherwise, return user profile.
    """
    # Try to get student profile
    student_row = await db.fetchrow(repository.get_student_by_user_id_query, user_id)
    if student_row:
        return model.StudentProfileFull(**dict(student_row))
    
    # Fall back to user profile
    user_row = await db.fetchrow(repository.get_user_profile_query, user_id)
    if user_row:
        return model.UserProfile(**dict(user_row))
    
    raise ValueError(f"Profile for user {user_id} not found")
