"""Service for Student operations"""

from datetime import date
from http.client import HTTPException
from typing import List, Optional, Union

from app.core import enums
from app.core.helper import convert_enums_to_values
from app.features.student import model, repository


async def create_student(student_data: dict, db) -> model.StudentFullRead:
    """Create a new student record"""
    
    # Convert enums to values
    student_data = convert_enums_to_values(student_data)
    
    # Prepare values in order of the query parameters
    values = [
        student_data.get('user_id'),
        student_data.get('name'),
        student_data.get('admission_type'),
        student_data.get('learning_mode'),
        student_data.get('department'),
        student_data.get('batch'),
        student_data.get('education_qualification'),
        student_data.get('admission_status', 'Approved'),  # Default for created students
        student_data.get('status', 'active'),
        student_data.get('start_time'),
        student_data.get('end_time'),
        student_data.get('subject'),
        student_data.get('courses'),
        student_data.get('dob'),
        student_data.get('father_name'),
        student_data.get('gender'),
        student_data.get('address'),
        student_data.get('religion'),
        student_data.get('caste'),
        student_data.get('date_of_joining', date.today()),  # date_of_joining
        student_data.get('contact'),
        student_data.get('email'),
        student_data.get('fees'),
        student_data.get('fee_type'),
        student_data.get('image_url'),
        

    ]
    print(f"Create Student: {values}")
    row = await db.fetchrow(repository.create_student_query, *values)
    print(f"Row:{row}")

    if student_data['email']:
        user = await db.fetchrow(
            "SELECT user_id FROM users WHERE email = $1", 
            student_data['email']
        )
        
        if user:
            # Link: write user_id into the new student row
            await db.execute(
                "UPDATE students SET user_id = $1 WHERE email = $2",
                user['user_id'], student_data['email']
            )
            # Upgrade their role in users table
            await db.execute(
                "UPDATE users SET role = 'student' WHERE user_id = $1",
                user['user_id']
            )
    return model.StudentFullRead(**dict(row))


async def get_student(student_id: int, db) -> Union[model.StudentFull, model.StudentBasic]:
    """Get student by ID"""
    row = await db.fetchrow(repository.get_student_by_id_query, student_id)
    if not row:
        raise ValueError(f"Student {student_id} not found")
    return model.StudentFullRead(**dict(row))


async def update_student(student_id: int, student_update: model.StudentUpdate, db) -> model.StudentFull:
    """Update student record"""
    
    data = student_update.model_dump(exclude_unset=True, mode='python')
    
    # Convert enums to values
    data = convert_enums_to_values(data)
    
    
    # Prepare values in order of the update query parameters
    values = [
        data.get('user_id'),
        data.get('name'),
        data.get('admission_type'),
        data.get('learning_mode'),
        data.get('department'),
        data.get('batch'),
        data.get('education_qualification'),
        data.get('admission_status'),
        data.get('status'),
        data.get('start_time'),
        data.get('end_time'),
        data.get('subject'),
        data.get('courses'),
        data.get('dob'),
        data.get('father_name'),
        data.get('gender'),
        data.get('address'),
        data.get('religion'),
        data.get('caste'),
        data.get('contact'),
        data.get('email'),
        data.get('fees'),
        data.get('fee_type'),
        data.get('fee_paid_till'),
        data.get('image_url'),
        student_id,  # Last parameter is the ID
       
    ]
    
    row = await db.fetchrow(repository.update_student_query, *values)
    return model.StudentFullRead(**dict(row))


async def delete_student(student_id: int, db) -> None:
    """Delete student record"""
    await db.execute(repository.delete_student_query, student_id)


async def get_students_list(
    db,
    department: Optional[enums.Department] = None,
    admission_type: Optional[enums.AdmissionType] = None,
    learning_mode: Optional[enums.LearningMode] = None,
    fee_type: Optional[enums.FeeType] = None,
    batch: Optional[enums.Batch] = None,
    fees_min: Optional[float] = None,
    fees_max: Optional[float] = None,
    joined_after: Optional[date] = None,
    joined_before: Optional[date] = None,
    search: Optional[str] = None,
) -> List[Union[model.StudentFull, model.StudentBasic]]:
    """Get list of students with optional filters"""
    
    # Convert enums to values
    dept_val = department.value if department else None
    adm_type_val = admission_type.value if admission_type else None
    learn_mode_val = learning_mode.value if learning_mode else None
    fee_type_val = fee_type.value if fee_type else None
    batch_val = batch.value if batch else None
    
    rows = await db.fetch(
        repository.get_students_filtered_query,
        dept_val,
        adm_type_val,
        learn_mode_val,
        fee_type_val,
        batch_val,
        fees_min,
        fees_max,
        joined_after,
        joined_before,
        search,
    )
    
    students =  [model.StudentFullRead(**dict(row)) for row in rows]
    
    if not students:
        raise HTTPException(
            status_code=404,
            detail="No students found."
        )
        
        
    print(type(students[0]))
    print(students[0])
    print(students[0].model_dump())


    return students
