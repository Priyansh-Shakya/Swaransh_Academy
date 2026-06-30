from fastapi import APIRouter 
from courses import service , model


router = APIRouter()

@router.get("/courses")
async def course_list():
    return  await service.readAllCourses()

@router.post('/course')
async def create_course(course: model.Course_Create):
    return await service.createCourse(course)

@router.put('/course/{id}')
async def update_course(course: model.Course_Create, id:int):
    return await service.updateCourse(course , id)

@router.delete('/course/{id}')
async def delete_course(id:int):
    return await service.courseDelete(id)

