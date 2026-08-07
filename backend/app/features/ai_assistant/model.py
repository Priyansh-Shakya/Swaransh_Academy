
from pydantic import BaseModel


class ChatMessage(BaseModel):
    role: str      # "user" | "assistant"
    content: str


class AssistanceQuery(BaseModel):
    name: str | None = None
    query: str
    conversation_history: list[ChatMessage] = []
    

class AssistanceResponse(BaseModel):
    response: str | None = None
