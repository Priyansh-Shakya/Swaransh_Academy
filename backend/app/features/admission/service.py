from app.core.enums import StudentStatus
from app.core.fcm_service import send_multiple_notifications, send_notification
from app.core.helper import convert_enums_to_values
from app.features.admission import model, queries
from app.features.student import service as student_service
from fastapi import HTTPException

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
    "fee_type",
    
)


async def create_admission_form(form: model.AdmissionFormCreate,user, db):
    """Create a new admission form"""
    user_id = user['id']
    data = form.model_dump(mode='python')
    data = convert_enums_to_values(data)
    print("Admission image url:", data['image_url'])
    values = [data[field] for field in FIELDS]
    values.append(user_id) 
    values.append(data["image_url"])
    row = await db.fetchrow(queries.create_addmision, *values)
    print("Admission Created:", row)


    #* Send notification to admin
    admins = await db.fetch(
    "SELECT fcm_token FROM users WHERE role = 'admin' AND fcm_token IS NOT NULL"
)

    tokens = [row["fcm_token"] for row in admins]
    #? call notification function
    print("FCM TOKEN FROM DB:", repr(tokens))
    send_multiple_notifications(tokens , "Admission Enquiry" , "A new admission enquiry has occured.")
    print("Sending Admission Application Notification TO admins.")
    return dict(row)
    

async def get_form_me(user, db):
    """Get admission forms for current user"""

    rows = await db.fetch(queries.get_admission_me, user['id'])
   
    result =  [dict(row) for row in rows]

    print("My Admission Forms:\n", result)
    return result

async def approve_form(admission_id: int, db):
    """Approve an admission form and create student record"""
    # Get admission record
    admission_row = await db.fetchrow("SELECT * FROM admissions WHERE id = $1", admission_id)
    if not admission_row:
        raise HTTPException(status_code=404, detail=f"Admission {admission_id} not found")
    
    admission = dict(admission_row)
    
    # Update admission status to Approved
    await db.fetchrow(queries.approved_admission_form, admission_id)
    
    # Create student record with pending_payment status
    student_data = {
        'user_id': admission.get('user_id'),
        'name': admission['name'],
        'admission_type': admission['admission_type'],
        'learning_mode': admission['learning_mode'],
        'department': admission['department'],
        'batch': admission['batch'],
        'education_qualification': admission['education_qualification'],
        'status': StudentStatus.pending_payment.value,
        'start_time': admission['start_time'],
        'end_time': admission['end_time'],
        'subject': admission['subject'],
        'courses': admission.get('courses'),
        'dob': admission['dob'],
        'father_name': admission['father_name'],
        'gender': admission['gender'],
        'address': admission['address'],
        'religion': admission.get('religion'),
        'caste': admission.get('caste'),
        'contact': admission.get('contact'),
        'email': admission['email'],
        'fees': admission['fees'],
        'fee_type': admission['fee_type'],
    }
    
    student = await student_service.create_student(student_data, db)

    #* Send approve notification!
    row = await db.fetchrow("""
    SELECT u.fcm_token
    FROM admissions a
    JOIN users u ON a.user_id = u.user_id
    WHERE a.id = $1
""", admission_id)
    print("FCM TOKEN FROM DB:", repr(row["fcm_token"]))
    if row and row["fcm_token"]:
        print("Sending approved notification ...")
        send_notification(
            row["fcm_token"],
            "Admission Approved",
            "Your admission has been approved!"
        )
    return student


async def decline_form(admission_id: int, db):
    """Decline an admission form"""
    row = await db.fetchrow(queries.declined_admission_form, admission_id)
    if not row:
        raise HTTPException(status_code=404, detail=f"Admission {admission_id} not found")
    if row:
        row = await db.fetchrow("""
            SELECT u.fcm_token
            FROM admissions a
            JOIN users u ON a.user_id = u.user_id
            WHERE a.id = $1
        """, admission_id)

        print("FCM TOKEN FROM DB:", repr(row["fcm_token"]))
        if row and row["fcm_token"]:
            print("Sending declined notification ...")
            send_notification(
                row["fcm_token"],
                "Admission Declined",
                "Your admission has been declined!"
            )
    return dict(row) if row else None


async def get_all_admissions(db, status: str | None = None):
    """Get list of all admission forms (admin only)"""
    if status:
        query = "SELECT * FROM admissions WHERE status = $1"
        rows = await db.fetch(query, status)
    else:
        rows = await db.fetch(queries.get_admission_form_list)
    return [dict(row) for row in rows]