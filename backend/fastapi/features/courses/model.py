from typing import Optional

from pydantic import BaseModel, Field
from enum import Enum
from core import enums

#* --------- Models



class Course(BaseModel):
    id: Optional[int] = None
    course_name: Optional[str] = Field(
        None,
        description='Display title, marketing-friendly. May not match form enums exactly.',
    )
    duration: Optional[str] = None
    fees: Optional[float] = None
    mode: Optional[enums.LearningMode] = None
    tag: Optional[enums.Tag] = None
    maps_to_department: Optional[enums.Department] = None
    maps_to_subject: Optional[str] = Field(
        None,
        description='Exact value to pre-fill into AdmissionFormCreate.subject when a\nstudent taps "Apply Now" from this course\'s detail screen.\nDeliberately separate from course_name since admin may want a\ncatchy display title ("Beginner Guitar Workshop") that differs\nfrom the standardized subject value the form expects ("Guitar").\n',
    )
    image_url: Optional[str] = Field(
        None,
        description="Points to a file in Supabase Storage, not a DB-stored blob.\nAdmin's create/edit-course flow uploads the file and saves the\nreturned public URL here.\n",
    )


class CourseCreate(BaseModel):
    course_name: str
    duration: str
    fees: float
    mode: enums.LearningMode
    tag: Optional[enums.Tag] = None
    maps_to_department: enums.Department
    maps_to_subject: str
    image_url: Optional[str] = None


class Course_Read(BaseModel):
    id: int

