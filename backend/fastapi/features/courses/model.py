from pydantic import BaseModel
from enum import Enum
from core import enums
#* -------- ENUMS


class Course_Tag(Enum):
    vocal=0
    instrumental=1



#* --------- Models

class Course_Base(BaseModel):
    course_name: str
    duration: str
    fees: float
    mode: enums.Learning_Mode
    tag: Course_Tag
    maps_to_department: enums.Department
    maps_to_subject: str

class Course_Create(BaseModel):
    pass

class Course_Read(BaseModel):
    id: int

