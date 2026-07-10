"""Service for User operations"""

from uuid import UUID

from app.core.enums import UserRole
from app.core.helper import convert_enums_to_values
from app.features.users import repository
from app.features.users.model import User, UserCreate


async def create_user(user_create: UserCreate, user_id: UUID, db) -> User:
    """
    Create or sync user profile and resolve role server-side.
    
    Role resolution logic:
    1. Check if user_id exists in pre-provisioned admin list
    2. Check if email matches an existing student email
    3. Otherwise set role as guest
    """
    
    data = user_create.model_dump(mode='python')
    data = convert_enums_to_values(data)
    
    user_name = data.get('user_name')
    email = data.get('email')
    fcm_token = data.get('fcm_token')
    
    # Default role is guest
    role = UserRole.anon.value
    
    # Check if email is pre-provisioned admin
    admin_check = await db.fetchrow(
        "SELECT * FROM users WHERE email = $1 AND role = 'admin'",
        email
    )
    
    if admin_check:
        role = UserRole.admin.value
    else:
        # Check if email matches a student email
        student_check = await db.fetchrow(
            repository.get_student_by_email_query,
            email
        )
        
        if student_check:
            # Link student to this user
            await db.fetchrow(
                repository.link_user_to_student_query,
                user_id,
                student_check['id']
            )
            role = UserRole.student.value
    
    # Create/update user profile
    user_row = await db.fetchrow(
        repository.create_user_query,
        user_id,
        user_name,
        role,
        email,
        fcm_token
    )
    
    user_dict = dict(user_row)
    return User(**user_dict)


async def get_user(user_id: UUID, db) -> User:
    """Get user profile by ID"""
    user_row = await db.fetchrow(
        repository.get_user_by_id_query,
        user_id
    )
    
    if not user_row:
        raise ValueError(f"User {user_id} not found")
    
    user_dict = dict(user_row)
    return User(**user_dict)


async def update_fcm_token(user_id: UUID, fcm_token: str, db) -> User:
    """Update user FCM token for push notifications"""
    user_row = await db.fetchrow(
        repository.update_user_fcm_token_query,
        fcm_token,
        user_id
    )
    
    if not user_row:
        raise ValueError(f"User {user_id} not found")
    
    user_dict = dict(user_row)
    return User(**user_dict)
