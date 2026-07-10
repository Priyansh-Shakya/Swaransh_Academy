"""Service for Courses operations"""

from typing import List

from app.core.helper import convert_enums_to_values
from app.features.courses import model, repository


async def create_course(course_create: model.CourseCreate, db) -> model.Course:
    """Create a new course"""
    data = course_create.model_dump(mode='python')
    data = convert_enums_to_values(data)
    
    values = [
        data.get('course_name'),
        data.get('duration'),
        data.get('fees'),
        data.get('mode'),
        data.get('tag'),
        data.get('maps_to_department'),
        data.get('maps_to_subject'),
        data.get('image_url'),
    ]
    
    row = await db.fetchrow(repository.create_course_query, *values)
    return model.Course(**dict(row))


async def get_course(course_id: int, db) -> model.Course:
    """Get course by ID"""
    row = await db.fetchrow(repository.get_course_by_id_query, course_id)
    if not row:
        raise ValueError(f"Course {course_id} not found")
    return model.Course(**dict(row))


async def update_course(course_id: int, course_update: model.CourseCreate, db) -> model.Course:
    """Update course"""
    data = course_update.model_dump(exclude_unset=True, mode='python')
    data = convert_enums_to_values(data)
    
    values = [
        data.get('course_name'),
        data.get('duration'),
        data.get('fees'),
        data.get('mode'),
        data.get('tag'),
        data.get('maps_to_department'),
        data.get('maps_to_subject'),
        data.get('image_url'),
        course_id,
    ]
    
    row = await db.fetchrow(repository.update_course_query, *values)
    return model.Course(**dict(row))


async def delete_course(course_id: int, db) -> None:
    """Delete course"""
    await db.execute(repository.delete_course_query, course_id)


async def get_all_courses(db) -> List[model.Course]:
    """Get all courses"""
    rows = await db.fetch(repository.get_all_courses_query)
    return [model.Course(**dict(row)) for row in rows]

