from enum import Enum


class Tag(str, Enum):
    instrumental = "instrumental"
    vocal = "vocal"


class AdmissionType(str, Enum):
    regular = "regular"
    band_training = "band_training"
    summer_camp = "summer_camp"
    custom = "custom"


class LearningMode(str, Enum):
    online = "online"
    offline = "offline"
    hybrid = "hybrid"


class Department(str, Enum):
    music = "music"
    dance = "dance"
    acting = "acting"
    music_video_production = "music_video_production"
    other = "other"


class Batch(str, Enum):
    morning = "morning"
    evening = "evening"


class EducationQualification(str, Enum):
    primary_school = "primary_school"
    high_school = "high_school"
    bachelors = "bachelors"
    masters = "masters"


class FeeType(str, Enum):
    monthly = "monthly"
    quarterly = "quarterly"
    half_yearly = "half_yearly"
    yearly = "yearly"


class AdmissionStatus(str, Enum):
    pending = "pending"
    approved = "approved"
    declined = "declined"


class StudentStatus(str, Enum):
    pending_payment = "pending_payment"
    active = "active"
    inactive = "inactive"


class PaymentType(str, Enum):
    admission = "admission"
    monthly = "monthly"
    quarterly = "quarterly"
    half_yearly = "half_yearly"
    yearly = "yearly"


class PaymentCategory(str, Enum):
    fee = "fee"
    admission = "admission"
    other = "other"


class PaymentMode(str, Enum):
    cash = "cash"
    upi = "upi"
    card = "card"
    bank_transfer = "bank_transfer"
    other = "other"


class PaymentStatus(str, Enum):
    active = "active"
    superseded = "superseded"


class UserRole(str, Enum):
    guest = "guest"
    student = "student"
    admin = "admin"


class StudentGender(str, Enum):
    male = "male"
    female = "female"
    nonbinary = "non_binary"


class Role(str, Enum):
    user = "user"
    assistant = "assistant"