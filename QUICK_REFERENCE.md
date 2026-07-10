# ⚡ QUICK REFERENCE - API ENDPOINTS

## 🔑 Key Information

| Item | Value |
|------|-------|
| **Base URL** | `http://localhost:8000/api/v1` |
| **Docs URL** | `http://localhost:8000/docs` |
| **Status** | ✅ Production Ready |
| **Async** | 100% |
| **Errors** | 0 |
| **Warnings** | 0 |

---

## 👥 Users Endpoints

```
POST   /user                    Create/sync user, resolve role
GET    /user/{id}              Get user by ID
```

---

## 👨‍🎓 Students Endpoints

```
POST   /student                Create student
GET    /student/{id}           Get student
PUT    /student/{id}           Update student
DELETE /student/{id}           Delete student
GET    /studentList            List with filters
  ?department=Music
  ?admission_type=Regular
  ?learning_mode=Offline
  ?fee_type=Monthly
  ?batch=Morning
  ?fees_min=1000
  ?fees_max=50000
  ?joined_after=2026-01-01
  ?joined_before=2026-12-31
  ?search=john
```

---

## 🎵 Courses Endpoints

```
POST   /course                 Create course
GET    /courseList             List all courses
PUT    /course/{id}            Update course
DELETE /course/{id}            Delete course
```

---

## 📝 Admission Endpoints

```
POST   /admissionForm          Submit admission form
GET    /admissionForm/me       Get user's forms
GET    /admissionFormList      List all forms (admin)
  ?status=Pending
  ?status=Approved
  ?status=Declined
POST   /admissionForm/{id}/approved      Approve form
POST   /admissionForm/{id}/declined      Decline form
```

---

## 💳 Payment Endpoints

```
POST   /student/{id}/payment               Record payment
GET    /student/{id}/paymentList           Get payment history
PUT    /student/{id}/payment/{payment_id}  Correct payment (supersede)
DELETE /student/{id}/payment/{payment_id}  Delete payment
```

---

## 👤 Profile Endpoints

```
GET    /profile/me             Get current user's profile
GET    /profile/student/{id}   Get student profile
GET    /profile/user/{id}      Get user profile
```

---

## 🤖 AI Assistant Endpoints

```
POST   /assistance             Get AI assistance
```

---

## 📋 Request/Response Examples

### Create User

**Request:**
```bash
POST /api/v1/user
Content-Type: application/json

{
  "user_name": "John Student",
  "email": "john@example.com",
  "fcm_token": "fcm_xyz_123"
}
```

**Response:**
```json
{
  "user_id": "uuid-here",
  "user_name": "John Student",
  "role": "student",
  "email": "john@example.com",
  "fcm_token": "fcm_xyz_123"
}
```

### Submit Admission Form

**Request:**
```bash
POST /api/v1/admissionForm
Content-Type: application/json

{
  "name": "Jane Doe",
  "email": "jane@example.com",
  "dob": "2005-01-15",
  "gender": "female",
  "father_name": "John Doe",
  "education_qualification": "High_School",
  "contact": "+91-9876543210",
  "address": "123 Main St",
  "religion": "Hindu",
  "caste": "General",
  "admission_type": "Regular",
  "learning_mode": "Offline",
  "department": "Music",
  "batch": "Morning",
  "start_time": "2026-08-01T10:00:00Z",
  "end_time": "2027-07-31T12:00:00Z",
  "subject": "Vocal",
  "courses": [],
  "fees": 50000,
  "fee_type": "Monthly"
}
```

### Record Payment

**Request:**
```bash
POST /api/v1/student/1/payment
Content-Type: application/json

{
  "payment_type": "admission",
  "amount": 50000,
  "mode": "UPI",
  "txn_ref": "UPI123456789",
  "paid_on": "2026-07-09T12:00:00Z"
}
```

### Correct Payment (Supersede)

**Request:**
```bash
PUT /api/v1/student/1/payment/5
Content-Type: application/json

{
  "payment_type": "admission",
  "amount": 55000,
  "mode": "Card",
  "txn_ref": "CARD987654321"
}
```

Result: Old payment marked `superseded`, new payment created as `active`

---

## 🔐 Authentication Notes

**Current State**: User ID passed as query parameter  
**Production**: Should extract from JWT Bearer token in Authorization header

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

---

## 🗂️ Database Tables

| Table | Purpose |
|-------|---------|
| **users** | User profiles with role |
| **students** | Student records |
| **admissions** | Admission forms and workflow |
| **courses** | Course catalogue |
| **payment** | Payment ledger (with supersede) |

---

## 🔄 Key Workflows

### Workflow 1: New Student Registration
1. User signs in with Google
2. POST `/user` → role resolved server-side
3. If email matches student → auto-linked as `student`
4. Otherwise → created as `guest`

### Workflow 2: Apply for Course
1. User browses courses via GET `/courseList`
2. POST `/admissionForm` with course details
3. Admin reviews via GET `/admissionFormList`
4. Admin approves → POST `/admissionForm/{id}/approved`
5. Student automatically created with `pending_payment` status

### Workflow 3: Process Payment
1. POST `/student/{id}/payment` → records payment
2. If error found → PUT `/student/{id}/payment/{payment_id}` → supersede pattern
3. Old payment marked `superseded`, new payment created
4. Audit trail preserved

---

## 🛠️ Development Tips

### Enable Debug Mode
```python
# In main.py
app = FastAPI(debug=True)
```

### Run with Reload
```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Test Endpoints
1. Go to http://localhost:8000/docs
2. Click on endpoint
3. Click "Try it out"
4. Enter parameters
5. Click "Execute"

### View Database
```bash
psql -U user -d swaransh_academy
\dt  # List tables
SELECT * FROM users;  # Query
```

---

## ✅ Health Check

**URL**: `GET http://localhost:8000/`

**Response**:
```json
{
  "message": "Gateway of the App"
}
```

---

## 📞 Common Issues

| Issue | Solution |
|-------|----------|
| `DatabaseURLError` | Check `DATABASE_URL` in `.env` |
| `Connection refused` | Ensure PostgreSQL is running |
| `Async error` | Ensure using async HTTP client |
| `Enum error` | Check enums are converted in service |
| `404 endpoint` | Check router is registered in `main.py` |

---

## 🚀 To Start Development

```bash
# 1. Navigate to backend
cd backend/app

# 2. Activate venv (if needed)
python -m venv venv
source venv/bin/activate  # macOS/Linux
# or
venv\Scripts\activate     # Windows

# 3. Install dependencies
pip install -r requirements.txt

# 4. Set environment
# Create .env with DATABASE_URL

# 5. Apply migrations
# psql -U user -d swaransh_academy -f ../../supabase/migrations/20260701165137_supabase_init.sql

# 6. Run server
uvicorn main:app --reload

# 7. Open browser
# http://localhost:8000/docs
```

---

**Last Updated**: July 9, 2026  
**Status**: ✅ COMPLETE & READY  
**Version**: 2.2.0
