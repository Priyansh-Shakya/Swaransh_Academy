from courses import model
from typing import List

async def createCourse(course: model.Course_Create) -> model.Course_Read:
    return

async def readAllCourses() -> List[model.Course_Read]:
    return 

async def updateCourse(course: model.Course_Create, id: int) -> model.Course_Read:
    return

async def courseDelete(id: int):
    return
