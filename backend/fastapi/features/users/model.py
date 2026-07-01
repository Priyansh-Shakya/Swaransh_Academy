from typing import Optional

from pydantic import BaseModel, EmailStr, Field
from uuid import UUID
from core import enums




class UserCreate(BaseModel):
    user_name: Optional[str] = None
    email: EmailStr
    fcm_token: Optional[str] = Field(
        None, description='Optional at creation; set/updated once push is configured.'
    )


class User(BaseModel):
    user_id: Optional[UUID] = Field(None, description='Matches Supabase Auth user id.')
    user_name: Optional[str] = None
    role: Optional[enums.UserRole] = None
    email: Optional[EmailStr] = None
    fcm_token: Optional[str] = None


class User_Read(User):
    user_id: UUID

    