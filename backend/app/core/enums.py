from enum import Enum


class Tag(Enum):
    Instrumental = 'Instrumental'
    Vocal = 'Vocal'

class AdmissionType(Enum):
    Regular = 'Regular'
    Band_Training = 'Band_Training'
    Summer_Camp = 'Summer_Camp'
    Custom = 'Custom'


class LearningMode(Enum):
    Online = 'Online'
    Offline = 'Offline'
    Hybrid = 'Hybrid'


class Department(Enum):
    Music = 'Music'
    Dance = 'Dance'
    Acting = 'Acting'
    Music_Video_Production = 'Music_Video_Production'
    Other = 'Other'


class Batch(Enum):
    Morning = 'Morning'
    Evening = 'Evening'


class EducationQualification(Enum):
    Primary_School = 'Primary_School'
    High_School = 'High_School'
    Bachelors = 'Bachelors'
    Masters = 'Masters'


class FeeType(Enum):
    Monthly = 'Monthly'
    Quarterly = 'Quarterly'
    Half_Yearly = 'Half_Yearly'
    Yearly = 'Yearly'


class AdmissionStatus(Enum):
    Pending = 'Pending'
    Approved = 'Approved'
    Declined = 'Declined'


class StudentStatus(Enum):
    pending_payment = 'pending_payment'
    active = 'active'
    inactive = 'inactive'


class PaymentType(Enum):
    admission = 'admission'
    monthly = 'monthly'
    quarterly = 'quarterly'
    half_yearly = 'half_yearly'
    yearly = 'yearly'


class PaymentMode(Enum):
    Cash = 'Cash'
    UPI = 'UPI'
    Card = 'Card'
    Bank_Transfer = 'Bank_Transfer'
    Other = 'Other'


class PaymentStatus(Enum):
    active = 'active'
    superseded = 'superseded'


class UserRole(Enum):
    guest = 'guest'
    student = 'student'
    admin = 'admin'


class StudentGender(Enum):
    male = 'male'
    female = 'female'
    nonbinary = 'non-binary'


class Role(Enum):
    user = 'user'
    assistant = 'assistant'

