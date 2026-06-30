from pydantic import BaseModel
from uuid import UUID
from enum import Enum

class user_role(Enum):
    anon = 0
    student =1
    admin = 2


class User_Base(BaseModel):
    user_name:str 
    email:str
    role: user_role
    fcm_token:str


class User_Create(User_Base):
    pass

class User_Read(User_Base):
    user_id: UUID

    