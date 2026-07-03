from app.core import enums
from app.core.enums import StudentGender
from app.features.admission import model
from app.features.admission import queries


FIELDS = (
    "name",
    "dob",
    "gender",
    "father_name",
    "education_qualification",
    "contact",
    "email",
    "address",
    "religion",
    "caste",
    "admission_type",
    "learning_mode",
    "department",
    "batch",
    "start_time",
    "end_time",
    "subject",
    "courses",
    "fees",
    "fee_type"
)


def create_admission_form(form: model.AdmissionFormCreate):
    data = form.model_dump()
    values = [data[field] for field in FIELDS]
    query = queries.create_addmision
    print(query)



from datetime import date

dummy_admission_form = model.AdmissionFormCreate(
    name="Priyansh Sharma",
    dob=date(2004, 5, 15),
    father_name="Rajesh Sharma",
    gender=StudentGender.male,
    education_qualification=enums.EducationQualification.Bachelors,
    contact="9876543210",
    email="priyansh.sharma@example.com",
    address="123, MG Road, Bhopal, Madhya Pradesh",
    religion="Hindu",
    caste="General",
    fees=25000.0,
    fee_type=enums.FeeType.Monthly,
)




create_admission_form(dummy_admission_form)

