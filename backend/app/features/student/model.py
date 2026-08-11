from datetime import date, time
from typing import Any
from uuid import UUID

from app.core import enums
from pydantic import BaseModel, EmailStr, Field


class StudentBasic(BaseModel):
    name: str | None = None
    admission_type: enums.AdmissionType | None = None
    learning_mode: enums.LearningMode | None = None
    department: enums.Department | None = None
    batch: enums.Batch | None = None
    start_time: time | None = None
    end_time: time | None = None
    subject: str | None = None
    courses: list[str] | None = None

class StudentBasicRead(StudentBasic):
    id: int


class StudentFull(StudentBasic):
    user_id: UUID | None = Field(
        None,
        description='Null for paper/cash students who never created an app account.',
    )
    image_url: str | None = Field(
        None, description='Profile photo (URL) of student, can be null.'
    )
    status: enums.StudentStatus | None = None
    dob: date | None = None
    father_name: str | None = None
    gender: enums.StudentGender | None = None
    education_qualification: enums.EducationQualification | None = None
    contact: str | None = Field(
        None, description='Optional - paper-only students may not have one on file yet.'
    )
    email: EmailStr | None = Field(
        None,
        description="Acts as the student login key: must match the Google account\nthe student signs in with for the account to be auto-linked.\nNull for paper/cash students who have no app account yet -\nadmin can add it later (via PUT) to enable login. Not\neditable by the student themself, since it's the linking key.\n",
    )
    address: str | None = None
    religion: str | None = Field(
        None,
        description='Optional. Compliance/records only - never used in list/filter UI.',
    )
    caste: str | None = Field(
        None,
        description='Optional. Compliance/records only - never used in list/filter UI.',
    )
    scholar_no: str | None = Field(
        None, description='Null until first (admission) payment succeeds.'
    )
    date_of_joining: date | None = Field(
        None, description='Null until first (admission) payment succeeds.'
    )
    fees: float | None = None
    fee_type: enums.FeeType | None = None
    fee_paid_till: date | None = Field(
        None,
        description='Denormalized summary, advanced on each recorded (active) payment.',
    )

class StudentFullRead(StudentFull):
    id: int

class StudentCreate(StudentFull):
    status: Any | None = None
    fee_paid_till: date | None = None
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
