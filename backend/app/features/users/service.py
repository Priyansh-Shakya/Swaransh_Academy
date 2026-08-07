"""Service for User operations"""

from uuid import UUID

from app.core.enums import UserRole
from app.core.helper import convert_enums_to_values
from app.features.users import repository
from app.features.users.model import User, UserCreate


async def create_user(user_create: UserCreate, user,db) -> User:
    """
    Create or sync user profile and resolve role server-side.
    
    Role resolution logic:
    1. Admin role will be determined by client side password verification...
    2. Check if email matches an existing student email
    3. Otherwise set role as guest
    """
    user_id = str(user['id'])
    print('---------------- From user service python: User id:', user_id)
    data = user_create.model_dump(mode='python')
    data['user_id'] = user_id
    data = convert_enums_to_values(data)
    
    user_name = data.get('user_name')
    email = data.get('email')
    fcm_token = data.get('fcm_token')
    role = data.get("role", UserRole.guest.value)
    print(f"Role from service function: {role}")
    
    
    

    # 2. Create the user row (NOW we have user_id)
    user_row = await db.fetchrow(
        repository.create_user_query,
        user_id , user_name, email, fcm_token, role  # pass resolved role here
    )

    user_dict = dict(user_row)

    user_dict["user_id"] = str(user_dict["user_id"])



    # 3. Link student AFTER user is created, using the new user_id
    result = await db.fetch(
        repository.link_user_to_student_query,
        user_dict['user_id'],   # now available
        user_dict['email']
    )
    print("Result of Student linking:", len(result))

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

async def check_user_role(user, db):
    user_id = user["id"]
    print("user_id:", user_id)

    row = await db.fetchrow(repository.check_role, user_id)
    print("row:", row)

    if row is None:
        print("No row found!")
        return None

    dict_row = dict(row)
    print(dict_row)

    return User(**dict_row)


async def verify_admin(password: str) -> bool:
    # TODO: Check from db or Ask claude the best design , maybe .env ...
    #? For now , using test password.

    return (password == "swaransh2024") 