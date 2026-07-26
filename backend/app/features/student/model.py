from datetime import date, time
from typing import Any, List, Optional
from uuid import UUID

from app.core import enums
from pydantic import AnyUrl, BaseModel, EmailStr, Field


class StudentBasic(BaseModel):
    name: str | None = None
    admission_type: Optional[enums.AdmissionType] = None
    learning_mode: Optional[enums.LearningMode] = None
    department: Optional[enums.Department] = None
    batch: Optional[enums.Batch] = None
    start_time: Optional[time] = None
    end_time: Optional[time] = None
    subject: Optional[str] = None
    courses: Optional[List[str]] = None

class StudentBasicRead(StudentBasic):
    id: int


class StudentFull(StudentBasic):
    user_id: Optional[UUID] = Field(
        None,
        description='Null for paper/cash students who never created an app account.',
    )
    image_url: Optional[AnyUrl] = Field(
        None, description='Profile photo (URL) of student, can be null.'
    )
    status: Optional[enums.StudentStatus] = None
    dob: Optional[date] = None
    father_name: Optional[str] = None
    gender: Optional[enums.StudentGender] = None
    education_qualification: Optional[enums.EducationQualification] = None
    contact: Optional[str] = Field(
        None, description='Optional - paper-only students may not have one on file yet.'
    )
    email: Optional[EmailStr] = Field(
        None,
        description="Acts as the student login key: must match the Google account\nthe student signs in with for the account to be auto-linked.\nNull for paper/cash students who have no app account yet -\nadmin can add it later (via PUT) to enable login. Not\neditable by the student themself, since it's the linking key.\n",
    )
    address: Optional[str] = None
    religion: Optional[str] = Field(
        None,
        description='Optional. Compliance/records only - never used in list/filter UI.',
    )
    caste: Optional[str] = Field(
        None,
        description='Optional. Compliance/records only - never used in list/filter UI.',
    )
    scholar_no: Optional[str] = Field(
        None, description='Null until first (admission) payment succeeds.'
    )
    date_of_joining: Optional[date] = Field(
        None, description='Null until first (admission) payment succeeds.'
    )
    fees: Optional[float] = None
    fee_type: Optional[enums.FeeType] = None
    fee_paid_till: Optional[date] = Field(
        None,
        description='Denormalized summary, advanced on each recorded (active) payment.',
    )

class StudentFullRead(StudentFull):
    id: int

class StudentCreate(StudentFull):
    status: Optional[Any] = None
    fee_paid_till: Optional[date] = None
    name: str
    father_name: Any
    dob: date
    contact: Any
    email: Any
    address: Any
    subject: str
    department: enums.Department
    learning_mode: enums.LearningMode
    batch: enums.Batch
    fees: float
    start_time: time
    end_time: time
    gender: Any
    education_qualification: Any


class StudentUpdate(StudentFull):
    pass
