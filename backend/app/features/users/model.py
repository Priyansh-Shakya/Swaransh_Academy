from uuid import UUID

from app.core import enums
from pydantic import BaseModel, EmailStr, Field


class UserCreate(BaseModel):
    user_name: str | None = None
    email: EmailStr
    role: enums.UserRole
    fcm_token: str | None = Field(
        None, description='Optional at creation; set/updated once push is configured.'
    )

class UserUpdate(BaseModel):
    email: str | None = None
    user_name: str | None = None
    role: str | None = None
    fcm_token: str | None = None

class User(BaseModel):
    user_name: str | None = None
    user_id: UUID | None = None
    role: enums.UserRole | None = None
    email: EmailStr | None = None
    fcm_token: str | None = None


class User_Read(User):
    user_id: UUID

    

class VerifyAdminPassword(BaseModel):
    password:str