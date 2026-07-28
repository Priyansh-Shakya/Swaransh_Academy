import json
from collections.abc import AsyncGenerator

import httpx
from app.features.ai_assistant.config import HF_MODEL, HF_ROUTER_URL, HF_TOKEN
from app.features.ai_assistant.model import ChatMessage


def _build_messages(query: str, history: list[ChatMessage]) -> list[dict]:
    # TODO: Add System Prompt here as well According to Role 'and' Append to messages at top.
    messages = [{"role": m.role, "content": m.content} for m in history]
    messages.append({"role": "user", "content": query})
    return messages


async def stream_ai_response(
    query: str,
    history: list[ChatMessage],
) -> AsyncGenerator[str, None]:
    """
    Yields plain text chunks as they arrive from the HF router.
    Raises httpx.HTTPStatusError if the upstream call fails.
    """
    print("Stream function called... AI service")
    payload = {
        "model": HF_MODEL,
        "messages": _build_messages(query, history),
        "stream": True,
    }
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