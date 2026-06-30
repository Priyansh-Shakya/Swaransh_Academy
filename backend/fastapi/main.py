from fastapi import FastAPI 
from features.courses.router import router as course_router
from features.users.router import router as user_router
from features.student.router import router as student_router

app = FastAPI()
app.include_router(course_router)
app.include_router(user_router)
app.include_router(student_router)
print("FastAPI Initilized ...")