from fastapi import APIRouter
from student import model , service

router = APIRouter()

@router.get('/studentfull')
async def read_student_full():
    return await service.read_student_full()

@router.get('/studentbasic')
async def read_student_basic():
    return await service.read_student_basic()

@router.post('/student')
async def create_student(stu: model.StudentFull):
    return await service.create_student(stu)

@router.put('/student/{id}')
async def update_student(stu: model.StudentFull, id:int):
    return await service.update_student(stu , id)

@router.delete('/student/{id}')
async def delete_student(id:int):
    return await service.delete_student(id)
