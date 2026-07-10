"""Router for Profile endpoints"""

from typing import Union
from uuid import UUID

from app.core.db import get_db
from app.features.profile import model, service
from fastapi import APIRouter, Depends

router = APIRouter(tags=['Profile'])


@router.get('/profile/me', tags=['Profile'])
async def get_my_profile(user_id: UUID, db=Depends(get_db)) -> Union[model.UserProfile, model.StudentProfileFull]:
    """
    Get current user's profile.
    
    Returns student profile if linked to a student, otherwise user profile.
    """
    return await service.get_my_profile(user_id, db)


@router.get('/profile/student/{student_id}', response_model=model.StudentProfileFull, tags=['Profile'])
async def get_student_profile(student_id: int, db=Depends(get_db)) -> model.StudentProfileFull:
    """
    Get student profile by student ID (admin view)
    """
    return await service.get_student_profile(student_id, db)


@router.get('/profile/user/{user_id}', response_model=model.UserProfile, tags=['Profile'])
async def get_user_profile(user_id: UUID, db=Depends(get_db)) -> model.UserProfile:
    """
    Get user profile by user ID
    """
    return await service.get_user_profile(user_id, db)
