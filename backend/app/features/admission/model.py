from __future__ import annotations

from datetime import date
from uuid import UUID

from pydantic import EmailStr, Field

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
    religion: str | None = None
    caste: str | None = None
    fees: float
    fee_type: enums.FeeType
    name: str
    image_url: str | None = None


class AdmissionForm(AdmissionFormCreate):
    id: int | None = None
    user_id: UUID | None = Field(None, description='Null if submitted anonymously.')
    status: AdmissionStatus | None = None
    

