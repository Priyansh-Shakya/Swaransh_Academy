"""Router for Profile endpoints"""

from typing import Literal, Union
from uuid import UUID

from app.core.auth.auth import get_current_user
from app.core.db import get_db
from app.features.profile import model, service
from app.features.student import model as studentModel
from fastapi import APIRouter, Depends
from pydantic import BaseModel

router = APIRouter(tags=['Profile'])

class StudentProfileResponse(BaseModel):
    type: Literal["student"]
    data: list[studentModel.StudentFullRead]

class UserProfileResponse(BaseModel):
    type: Literal["user"]
    data: model.UserProfile

@router.get('/profile/me', tags=['Profile'])
async def get_my_profile(
    user = Depends(get_current_user),
    db = Depends(get_db),
) -> Union[StudentProfileResponse, UserProfileResponse]:
    """Returns linked student(s) if any, otherwise the bare user profile."""
    return await service.get_my_profile(user, db)

@router.get('/profile/student/{student_id}', response_model=studentModel.StudentFullRead, tags=['Profile'])
async def get_student_profile(student_id: int, db=Depends(get_db)) -> studentModel.StudentFullRead:
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
