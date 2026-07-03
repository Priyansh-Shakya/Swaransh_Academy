from __future__ import annotations

from datetime import date

from typing import  Optional
from uuid import UUID

from pydantic import AnyUrl, AwareDatetime, BaseModel, EmailStr, Field

from ...core import enums
from ...core.enums import AdmissionStatus, StudentGender
from ...features.student.model import StudentBasic




class AdmissionFormCreate(StudentBasic):
    dob: date
    father_name: str
    gender: StudentGender
    education_qualification: enums.EducationQualification
    contact: str
    email: EmailStr = Field(
        ...,
        description='Required at submission time (unlike StudentFull.email which\nis nullable) - an applicant filling the form digitally is\nexpected to provide it, since this becomes their future\nlogin key once approved.\n',
    )
    address: str
    religion: Optional[str] = None
    caste: Optional[str] = None
    fees: float
    fee_type: enums.FeeType
    name: str


class AdmissionForm(AdmissionFormCreate):
    id: Optional[int] = None
    user_id: Optional[UUID] = Field(None, description='Null if submitted anonymously.')
    status: Optional[AdmissionStatus] = None

