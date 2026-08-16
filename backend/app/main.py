from contextlib import asynccontextmanager
from pathlib import Path

import joblib
from app.core.db import close_db, init_db
from app.features.admission.router import router as admission_router
from app.features.ai_assistant.router import router as ai_assistant_router
from app.features.courses.router import router as course_router
from app.features.extra_config.admin_image import router as admin_image_router
from app.features.payment.router import router as payment_router
from app.features.profile.router import router as profile_router
from app.features.student.router import router as student_router
from app.features.users.router import router as user_router
from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware


def load_initial_configs(app: FastAPI):
    print(">>> Loading initial configs...")

    BASE_DIR = Path(__file__).resolve().parent
    PROJECT_DIR = BASE_DIR.parent

    env_path = PROJECT_DIR / ".env"

    print(">>> ENV path:", env_path)
    print(">>> ENV exists:", env_path.exists())

    load_dotenv(env_path)
    print(">>> .env loaded")

    vectorizer_path = BASE_DIR / "models" / "vectorizer.pkl"
    classifier_path = BASE_DIR / "models" / "classifier.pkl"

    print(">>> Vectorizer path:", vectorizer_path)
    print(">>> Vectorizer exists:", vectorizer_path.exists())

    print(">>> Loading vectorizer...")
    app.state.vec = joblib.load(vectorizer_path)
    print(">>> Vectorizer loaded")

    print(">>> Loading classifier...")
    app.state.clf = joblib.load(classifier_path)
    print(">>> Classifier loaded")

    print(">>> INITIAL CONFIGS LOADED SUCCESSFULLY")

    
@asynccontextmanager
async def lifespan(app: FastAPI):
    print(">>> LIFESPAN STARTED")

    load_initial_configs(app)

    print(">>> Initializing DB...")
    await init_db()

    yield

    await close_db()

app = FastAPI(
    lifespan=lifespan,
    title='Swaransh Academy of Music & Art - API',
    version='2.2.0',
    
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
app.include_router(admin_image_router)

print("FastAPI Initilized ...")



@app.get("/")
async def root():
    return {"message": "Gateway of the App"}