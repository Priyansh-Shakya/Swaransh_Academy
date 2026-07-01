
from pydantic import BaseModel  , Field
from typing import List, Optional

from backend.fastapi.core.enums import Role 


class HistoryItem(BaseModel):
    role: Optional[Role] = None
    content: Optional[str] = None


class AssistanceQuery(BaseModel):
    query: str
    history: Optional[List[HistoryItem]] = Field(
        None,
        description='Last up to 10 messages, kept client-side. Sent each call; backend is stateless.',
    )


class AssistanceResponse(BaseModel):
    response: Optional[str] = None
