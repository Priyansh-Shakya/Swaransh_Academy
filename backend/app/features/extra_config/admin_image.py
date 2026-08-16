from app.core.db import get_db
from fastapi import APIRouter, Depends
from pydantic import BaseModel

router  = APIRouter()

class AdminImagePath(BaseModel):
    admin_name: str
    path: str


@router.get(
    "/config/admin/images",
    response_model=list[AdminImagePath],
)
async def get_admin_images(db=Depends(get_db)):
    rows = await db.fetch("""
        SELECT key, value
        FROM config
        WHERE key LIKE 'admin_image_%'
        ORDER BY key
    """)

    return [
        AdminImagePath(
            admin_name=row["key"].removeprefix("admin_image_"),
            path=row["value"],
        )
        for row in rows
    ]