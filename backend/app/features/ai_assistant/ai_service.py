import json
import time
from collections.abc import AsyncGenerator

import httpx
from app.features.ai_assistant.config import HF_MODEL, HF_ROUTER_URL, HF_TOKEN
from app.features.ai_assistant.model import ChatMessage
from app.features.ai_assistant.sys_prompt import (
    ACADEMY_INFO,
    ADMIN_PROMPT,
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
    name: str
) -> list[dict]:
    print("Name from build message function: ", name)
    prompt = SYSTEM_PROMPT 
    
    
    
    if role in ("guest", "student"):
        prompt += "\n\n" + ACADEMY_INFO
    elif role == "admin":
        prompt += "\n\n" + ADMIN_PROMPT

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
    name
) -> AsyncGenerator[str, None]:
    """
    Yields plain text chunks as they arrive from the HF router.
    Raises httpx.HTTPStatusError if the upstream call fails.
    """
    print("Stream function called... AI service")
    role = await check_role(user, db)
    print("Fetched role:" , role)
    message = await _build_messages(query, history, role, name)
    print("PROMPT:\n", message)

    #* Response Lenght Parameter
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
    payload = {
        "model": HF_MODEL,
        "messages": message,
        "stream": True,
        "max_tokens": ROLE_CONFIG[role]["max_tokens"],
    }
    print("PAYLOAD:\n", payload)
    headers = {
        "Authorization": f"Bearer {HF_TOKEN}",
        "Content-Type": "application/json",
    }


    async with httpx.AsyncClient(timeout=60.0) as client, client.stream(
        "POST", HF_ROUTER_URL, headers=headers, json=payload
    ) as response:
        response.raise_for_status()
        line_count = 0
        chunk_count = 0
        async for line in response.aiter_lines():
            line_count += 1
            print(f"[HF] raw line: {line!r}") 
            if not line or not line.startswith("data: "):
                continue

            raw = line[len("data: "):].strip()
            if raw == "[DONE]":
                
                print(f"[HF] done. total lines={line_count}, chunks yielded={chunk_count}")
                
                return

            chunk = _extract_delta_content(raw)
            if chunk:
                chunk_count += 1
                
                yield chunk
                print(
        f"[BACKEND AFTER YIELD] "
        f"{time.time()*1000:.0f}ms "
        f"chunk={chunk_count}"
    )

            print(f"[HF] stream ended without [DONE]. lines={line_count}, chunks={chunk_count}")


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