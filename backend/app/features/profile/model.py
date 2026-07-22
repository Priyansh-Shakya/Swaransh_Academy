"""Profile models"""

from typing import Optional
from uuid import UUID

from app.core import enums
from pydantic import BaseModel, EmailStr


class UserProfile(BaseModel):
    """User profile with basic info"""
    user_id: UUID
    user_name: Optional[str] = None
    email: Optional[EmailStr] = None
    role: enums.UserRole 
    fcm_token: Optional[str] = None

