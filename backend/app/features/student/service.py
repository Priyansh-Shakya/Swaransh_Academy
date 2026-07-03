from student import model

async def read_student_basic() -> list[model.StudentBasicRead]:
    return

async def read_student_full() -> list[model.StudentFullRead]:
    return

async def create_student(stu: model.StudentFull) -> model.StudentFullRead:
    return

async def update_student(stu: model.StudentFull , id:int):
    return

async def delete_student(id: int):
    return  