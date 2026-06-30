from enum import Enum

class Learning_Mode(Enum):
    online=0
    offline=1
    hybrid=2


class Department(Enum):
    music =0
    dance=1
    acting=2
    music_video_production=3
    other=4

class Batch(Enum):
    morning =0
    evening =1

class Student_Status(Enum):
    payment_pending=0
    active=1
    inactive=2

class Student_Gendre(Enum):
    male=0
    female=1
    nonbinary=2


class Education_Qualification(Enum):
    primary_school =0
    high_school =1
    bachelors=2
    masters=3

class Fee_Type(Enum):
    monthly=0
    quarterly=1
    half_yearly=2
    yearly=3