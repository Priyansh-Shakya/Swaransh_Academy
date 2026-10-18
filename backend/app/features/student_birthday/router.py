from fastapi import APIRouter
from app.core.fcm_service import send_notification

router = APIRouter()


#* FORMAT
# {
#   "student_id": "uuid-or-int-here",
#   "scholar_no": "12345",
#   "name": "John Doe",
#   "department": "Computer Science",
#   "fcm_token": "eXamPleFCMTokenString123..."
# }
from pydantic import BaseModel

class BirthdayNotification(BaseModel):
    student_id: int | str | None = None
    scholar_no: str | None = None
    name: str | None = None
    department: str | None = None
    fcm_token: str | None = None
    

@router.post('/students/birthday/')
async def get_students_birthday(payload: BirthdayNotification):
    """
    Receive student birthday trigger from Supabase cron via pg_net.
    Send a push FCM notification if fcm_token exists.
    """
    print("STUDENT BIRTHDAY DATA RECEIVED IN ROUTER:\n", payload)
    
    if payload.fcm_token:
        await send_notification(
            fcm_token=payload.fcm_token, 
            task="🎵 Happy Birthday! ",
            msg=f"Wishing you a very musical birthday {payload.name}"
        )
    
    print({"status": "success", "processed_student": payload.name})
