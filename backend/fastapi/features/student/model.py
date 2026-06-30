from pydantic import BaseModel
from enum import Enum
from core import enums
from courses import model as course_model
#*------ ENUM
class AdmissionType(Enum):
    regular=0
    band_training=1
    summer_camp=2
    custom=3


class Student_Base(BaseModel):
    name:str
    admission_type: AdmissionType
    learning_mode: enums.Learning_Mode
    department: enums.Department
    batch: enums.Batch
    start_time: str
    end_time: str
    subject: str
    courses: list[course_model.Course_Read]
    image_url: str
    
class StudentBasic(Student_Base):
    pass

class StudentBasicRead(StudentBasic):
    id: int

class StudentFull(Student_Base):
    status: enums.Student_Status
    dob: str
    father_name: str
    gendre: enums.Student_Gendre
    education_qualification: enums.Education_Qualification
    contact: str
    email: str
    address: str
    religion: str | None = None
    caste: str | None = None 
    scholar_no: str | None = None
    date_of_joining: str
    fees: float
    fee_type: enums.Fee_Type
    fee_paid_until: str

class StudentFullRead(StudentFull):
    id: int

