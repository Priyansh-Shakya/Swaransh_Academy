
import json

from app.features.ai_assistant.model import ChatMessage
from app.features.ai_assistant.sys_prompt import (
    ACADEMY_INFO,
    ADMIN_CHAT_PROMPT,
    DB_DATA_USAGE,
    SYSTEM_PROMPT,
)


#* Removes Empty/Null fields from SQL fetched data we pass to LLM
def strip_empty(obj):
    if isinstance(obj, dict):
        return {k: strip_empty(v) for k, v in obj.items() if v not in (None, "", [])}
    if isinstance(obj, list):
        return [strip_empty(x) for x in obj]
    return obj



async def check_role(user, db):
    if user is None:
        print("Returning guest role ...")
        return 'guest'
    role = await db.fetchrow('select role from users where user_id = $1', user['id'])
    role = role['role'] if role else 'guest'
    print("Role fetched from DB: ", role)
    return role

async def _build_messages(
    query: str,
    history: list[ChatMessage],
    role: str,
    name: str,
    agent_data: str | list | dict | None = None,
    executed_sql:str | None = None
) -> list[dict]:
    print("Name from build message function: ", name)
    prompt = SYSTEM_PROMPT 
    
    if agent_data is not None:
        prompt += f"\nAdmin Name: {name}\n" + DB_DATA_USAGE
        
        if executed_sql:
            prompt += f"\n[EXECUTED SQL QUERY]:\n```sql\n{executed_sql}\n```"
            
        prompt += "\n[DATA FETCH RESULT]:\n" + json.dumps(strip_empty(agent_data), separators=(",", ":"), default=str)
        print("Agent Prompt:\n", prompt)
    else:
        if role in ("guest", "student"):
            prompt += "\n\n" + ACADEMY_INFO + "For guests and students , keep response length quite short , not more than 4 or 5 lines unless the response require more."
        elif role == "admin":
            prompt += "\n\n" + ADMIN_CHAT_PROMPT + "\nThis Admin Query was classified as normal chat query. Hence, Database Schema is not provided in this prompt."

        if name:
            prompt += f"\n\nCurrent User:\nName: {name}\nRole: {role}"

    messages = [
        {
            "role": "system",
            "content": prompt,
        }
    ]

    messages.extend(
        {"role": m.role, "content": m.content}
        for m in history
    )

    messages.append(
        {
            "role": "user",
            "content": query,
        }
    )

    return messages
