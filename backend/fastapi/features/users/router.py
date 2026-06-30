from fastapi import APIRouter
from model import User_Create 
from users import service

router = APIRouter()

@router.post("user")
async def create_user(user: User_Create):
    return await service.create_user(user)

@router.get("user/{id}")
async def get_user_by_id(id:int):
    return await service.get_user_by_id(id)