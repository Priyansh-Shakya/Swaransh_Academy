from typing import Optional
from uuid import UUID

from app.core import enums
from pydantic import BaseModel, EmailStr, Field


class UserCreate(BaseModel):
    user_name: Optional[str] = None
    email: EmailStr
    role: enums.UserRole
    fcm_token: Optional[str] = Field(
        None, description='Optional at creation; set/updated once push is configured.'
    )


class User(BaseModel):
    user_name: Optional[str] = None
    role: Optional[enums.UserRole] = None
    email: Optional[EmailStr] = None
    fcm_token: Optional[str] = None


class User_Read(User):
    user_id: UUID

    

class VerifyAdminPassword(BaseModel):
    password:str