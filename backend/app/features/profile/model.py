"""Profile models"""

from datetime import date, time
from typing import Optional
from uuid import UUID

from app.core import enums
from pydantic import AnyUrl, BaseModel, EmailStr


class UserProfile(BaseModel):
    """User profile with basic info"""
    id: int  #! changed NEED TO CHECK
    user_id: UUID
    user_name: Optional[str] = None
    email: Optional[EmailStr] = None
    fcm_token: Optional[str] = None


class StudentProfileBasic(BaseModel):
    """Basic student profile info (public)"""
    id: int
    name: str
    department: enums.Department
    batch: enums.Batch
    image_url: Optional[AnyUrl] = None


class StudentProfileFull(BaseModel):
    """Full student profile (self and admin)"""
    id: int
    user_id: Optional[UUID] = None
    name: str
    admission_type: enums.AdmissionType
    learning_mode: enums.LearningMode
    department: enums.Department
    batch: enums.Batch
    start_time: Optional[time] = None
    end_time: Optional[time] = None
    subject: str
    dob: Optional[date] = None
    father_name: Optional[str] = None
    gender: Optional[enums.StudentGender] = None
    education_qualification: Optional[enums.EducationQualification] = None
    contact: Optional[str] = None
    email: Optional[EmailStr] = None
    address: Optional[str] = None
    religion: Optional[str] = None
    caste: Optional[str] = None
    fees: float
    fee_type: enums.FeeType
    fee_paid_till: Optional[date] = None
    status: enums.StudentStatus
    image_url: Optional[AnyUrl] = None
