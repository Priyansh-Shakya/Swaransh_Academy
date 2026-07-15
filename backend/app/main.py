from contextlib import asynccontextmanager

from app.core import env
from app.core.db import close_db, init_db
from app.features.admission.router import router as admission_router
from app.features.ai_assistant.router import router as ai_assistant_router
from app.features.courses.router import router as course_router
from app.features.payment.router import router as payment_router
from app.features.profile.router import router as profile_router
from app.features.student.router import router as student_router
from app.features.users.router import router as user_router
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

print(env.placeholder) #? To avoid RUFF removing the import of env.py


@asynccontextmanager
async def lifespan(app: FastAPI):
    #? Startup
    await init_db()
    yield
    #? shutdown
    await close_db()


app = FastAPI(
    lifespan=lifespan,
    title='Swaransh Academy of Music & Art - API',
    version='2.2.0',
    description='# Swaransh Academy API\n\n## Summary\nFeatures:\n- Users: Identity record linked to Supabase Auth (Google Sign-In).\n  role is resolved server-side, never client-settable.\n- Courses: Public course catalogue. Full admin CRUD.\n- Students: Student records, role-aware shape (Admin = full, Student = basic).\n  Full admin CRUD - many students are paper/cash enrollments who never\n  touch the app, so admin must be able to manually create/edit/delete.\n- Admission: Admission workflow (apply -> approve/decline -> pay -> active).\n- Payments: Ledger, primarily insert-only, with admin-only correction via\n  a supersede pattern (see below) rather than true mutation.\n- AI Assistance: Role-aware, stateless, streaming chat assistant.\n\n## Key design decisions (do not re-litigate without reason)\n- Auth is handled by Supabase Auth (Google Sign-In). This API\'s `User` schema\n  is a profile record keyed by the Supabase `user_id`, not a credential store.\n- Role-selection-first model: on fresh install, the user picks Anon /\n  Student / Admin before any Supabase call happens.\n  - Anon: no auth at all, pure local UI state. Browse only.\n  - Admin: Google sign-in -> backend checks if the signed-in email is\n    pre-provisioned with role=admin in `users`. Rejected otherwise.\n  - Student: Google sign-in -> backend matches the signed-in email\n    against an existing `students.email`. If found, that student row is\n    linked (students.user_id set) and users.role becomes `student`. No\n    separate verification step - the matched email IS the proof,\n    since it\'s already Google-verified. If no match, the student is\n    told to contact the academy to get their email updated on file\n    (admin fixes via existing student-edit endpoints - no special\n    "request a fix" flow needed at this scale).\n  - `role` is therefore ALWAYS resolved server-side, never accepted\n    from the client on creation or update.\n- Student row is created at admission **approval** time, with\n  `status = pending_payment`. Payment does NOT create the student row -\n  it activates it. This avoids a nullable dual-FK on payments.\n- `payments` table/endpoint has exactly one FK: `student_id`. Never nullable.\n  `payment_type` distinguishes admission vs recurring payments as a label,\n  not a structural fork.\n- Many students are local/offline enrollments (cash, paper registers) who\n  never install the app. Admin therefore has full manual CRUD on\n  Students, Courses, AND Payments - the app must work as the academy\'s\n  record system, not just a self-service portal for app users.\n  `email`/`contact` on StudentFull are nullable for exactly this reason -\n  a paper student may have neither captured yet. Typos/omissions are\n  expected and tolerated; admin\'s existing edit endpoints are the fix,\n  no extra verification machinery needed at this scale.\n- Payment corrections use a SUPERSEDE pattern, not in-place mutation:\n  PUT does not overwrite a row. It inserts a new corrected row, then\n  flags the old row `status = superseded` with `superseded_by` pointing\n  to the new row\'s id. This preserves an audit trail while still letting\n  admin fix mistakes. DELETE remains a true hard delete, reserved for\n  genuine duplicates (e.g. same payment logged twice), not corrections.\n- `paid_on` is admin-settable on creation (not server-forced to "now"),\n  since admin frequently backfills a paper register days/weeks after\n  the actual payment happened. If omitted, backend defaults to now.\n- No pagination yet (academy has ~100 students). `/studentList` supports\n  optional filter/search query params, applied server-side. Revisit\n  pagination only if scale changes - contract impact will be additive\n  (limit/offset params), not breaking.\n- `StudentBasic` (visible to students about other students) intentionally\n  excludes contact info, fees, religion, caste, address, dob - anything\n  personal/financial. `StudentFull` (admin only, and self) has everything.\n',
    
)

#? Allow CORS for dev only
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],      # dev only
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(course_router)
app.include_router(user_router)
app.include_router(student_router)
app.include_router(ai_assistant_router)
app.include_router(payment_router)
app.include_router(admission_router)
app.include_router(profile_router)

print("FastAPI Initilized ...")



@app.get("/")
async def root():
    return {"message": "Gateway of the App"}