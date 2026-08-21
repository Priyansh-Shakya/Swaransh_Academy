import json
from collections.abc import AsyncGenerator

import httpx
from app.features.ai_assistant.config import HF_MODEL, HF_ROUTER_URL, HF_TOKEN
from app.features.ai_assistant.helper import _build_messages
from app.features.ai_assistant.model import ChatMessage


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