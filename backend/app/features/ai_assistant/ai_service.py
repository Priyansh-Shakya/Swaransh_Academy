from collections.abc import AsyncGenerator

from app.features.ai_assistant.helper import _build_messages
from app.features.ai_assistant.model import ChatMessage
from app.features.ai_assistant.service.stream_service import AIServiceStream

ai_service = AIServiceStream()

async def stream_ai_response(
    query: str,
    history: list[ChatMessage],
    user,
    db,
    name,
    agent_call: bool,
    agent_data: str,
    executed_sql: str,
    role:str
) -> AsyncGenerator[str, None]:

    print("Stream function called... AI service")

    if agent_call and agent_data:
        print("Agent call detected. Skipping role check.")

        role = "admin"  # only if your _build_messages needs a role fallback
        message = await _build_messages(
            query,
            history,
            role,
            name,
            agent_data,
            executed_sql
            
        )

        max_tokens = 800

    else:
        
        print("Fetched role:", role)

        message = await _build_messages(
            query,
            history,
            role,
            name,
            None,
        )

        ROLE_CONFIG = {
            "guest": {
                "max_tokens": 250,
            },
            "student": {
                "max_tokens": 250,
            },
            "admin": {
                "max_tokens": 800,
            },
        }

        max_tokens = ROLE_CONFIG[role]["max_tokens"]


    print("PROMPT:\n", message)

    async for chunk in ai_service.stream(
        messages=message,
        max_tokens=max_tokens,
    ):
        yield chunk

