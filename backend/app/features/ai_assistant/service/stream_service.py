import json
import os
from collections.abc import AsyncGenerator

import httpx
from app.features.ai_assistant.config import HF_MODEL, HF_ROUTER_URL, HF_TOKEN
from dotenv import load_dotenv

load_dotenv()



OPENROUTER_API_KEY = os.getenv("OPENROUTER_API_KEY")


OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions"


class AIServiceStream:

    async def stream(
        self,
        messages: list[dict],
        max_tokens: int,
    ) -> AsyncGenerator[str, None]:

        # -------------------------
        # 1. Hugging Face
        # -------------------------
        try:
            print("[AI] Streaming with Hugging Face...")

            payload = {
                "model": HF_MODEL,
                "messages": messages,
                "stream": True,
                "max_tokens": max_tokens,
                "temperature": 0.65, #* Creativity
            }

            headers = {
                "Authorization": f"Bearer {HF_TOKEN}",
                "Content-Type": "application/json",
            }

            async with httpx.AsyncClient(timeout=60.0) as client:  # noqa: SIM117
                async with client.stream(
                    "POST",
                    HF_ROUTER_URL,
                    headers=headers,
                    json=payload,
                ) as response:

                    print(f"[AI] HF status: {response.status_code}")

                    if response.is_error:
                        error_body = await response.aread()
                        print(
                            "[AI] HF error body:",
                            error_body.decode(errors="replace")
                        )
                        response.raise_for_status()

                    async for line in response.aiter_lines():

                        if not line or not line.startswith("data: "):
                            continue

                        raw = line[len("data: "):].strip()

                        if raw == "[DONE]":
                            print("[AI] HF stream completed.")
                            return

                        chunk = self._extract_delta_content(raw)

                        if chunk:
                            yield chunk

        except httpx.HTTPStatusError as e:
            await e.response.aread()
            print(f"[AI] HF error body: {e.response.text}")
            status = e.response.status_code

            print(f"[AI] HF HTTP error: {status}")

            if status not in {402, 429, 500, 502, 503, 504}:
                raise

            print("[AI] HF unavailable → falling back to OpenRouter.")

        except (httpx.TimeoutException, httpx.ConnectError) as e:

            print(f"[AI] HF connection error: {e}")
            print("[AI] HF unavailable → falling back to OpenRouter.")

        # -------------------------
        # 2. OpenRouter
        # -------------------------
        try:
            print("[AI] Streaming with OpenRouter...")

            payload = {
                "model": "openrouter/free",
                "messages": messages,
                "stream": True,
                "max_tokens": max_tokens,
                "temperature": 0.65,
            }

            headers = {
                "Authorization": f"Bearer {OPENROUTER_API_KEY}",
                "Content-Type": "application/json",
            }

            async with httpx.AsyncClient(timeout=60.0) as client:  # noqa: SIM117
                async with client.stream(
                    "POST",
                    OPENROUTER_URL,
                    headers=headers,
                    json=payload,
                ) as response:

                    print(f"[AI] OpenRouter status: {response.status_code}")

                    response.raise_for_status()

                    async for line in response.aiter_lines():

                        if not line or not line.startswith("data: "):
                            continue

                        raw = line[len("data: "):].strip()

                        if raw == "[DONE]":
                            print("[AI] OpenRouter stream completed.")
                            return

                        chunk = self._extract_delta_content(raw)

                        if chunk:
                            yield chunk

        except Exception as e:

            print(f"[AI] OpenRouter streaming failed: {e}")
            raise

    @staticmethod
    def _extract_delta_content(raw_json: str) -> str | None:

        try:
            data = json.loads(raw_json)
        except json.JSONDecodeError:
            return None

        choices = data.get("choices") or []

        if not choices:
            return None

        delta = choices[0].get("delta") or {}

        return delta.get("content")