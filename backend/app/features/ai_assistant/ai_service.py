import json
from collections.abc import AsyncGenerator

import httpx
from app.features.ai_assistant.config import HF_MODEL, HF_ROUTER_URL, HF_TOKEN
from app.features.ai_assistant.model import ChatMessage
from app.features.ai_assistant.sys_prompt import (
    ACADEMY_INFO,
    ADMIN_CHAT_PROMPT,
    DB_DATA_USAGE,
    SYSTEM_PROMPT,
)


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
    agent_data:str,
) -> list[dict]:
    print("Name from build message function: ", name)
    prompt = SYSTEM_PROMPT 
    
    if agent_data is not None:
        
        

        prompt +=f"Admin Name: {name}" + DB_DATA_USAGE + "\n" + json.dumps(agent_data, indent=2, default=str)
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

async def stream_ai_response(
    query: str,
    history: list[ChatMessage],
    user,
    db,
    name,
    agent_call: bool,
    agent_data: str,
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

    payload = {
        "model": HF_MODEL,
        "messages": message,
        "stream": True,
        "max_tokens": max_tokens,
    }

    headers = {
        "Authorization": f"Bearer {HF_TOKEN}",
        "Content-Type": "application/json",
    }


    async with httpx.AsyncClient(timeout=60.0) as client, client.stream(
        "POST",
        HF_ROUTER_URL,
        headers=headers,
        json=payload
    ) as response:

        response.raise_for_status()

        line_count = 0
        chunk_count = 0

        async for line in response.aiter_lines():

            line_count += 1
            

            if not line or not line.startswith("data: "):
                continue

            raw = line[len("data: "):].strip()

            if raw == "[DONE]":
                print(
                    f"[HF] done. total lines={line_count}, "
                    f"chunks yielded={chunk_count}"
                )
                return

            chunk = _extract_delta_content(raw)

            if chunk:
                chunk_count += 1
                yield chunk

                

        print(
            f"[HF] stream ended without [DONE]. "
            f"lines={line_count}, chunks={chunk_count}"
        )

def _extract_delta_content(raw_json: str) -> str | None:
    try:
        data = json.loads(raw_json)
    except json.JSONDecodeError:
        return None

    choices = data.get("choices") or []
    if not choices:
        return None

    delta = choices[0].get("delta", {})
    return delta.get("content")