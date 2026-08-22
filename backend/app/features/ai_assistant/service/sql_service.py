import os

import httpx
from app.features.ai_assistant.config import HF_MODEL, HF_ROUTER_URL, HF_TOKEN
from dotenv import load_dotenv

load_dotenv()



OPENROUTER_API_KEY = os.getenv("OPEN_ROUTER_API_KEY")


OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions"


class AIService:

    async def generate_sql(
        self,
        messages
    ) -> str:

        

        # # -------------------------
        # # 1. Hugging Face
        # # -------------------------
        try:
            print("[AI] Trying Hugging Face...")

            payload = {
                "model": HF_MODEL,
                "messages": messages,
                "temperature": 0,
            }

            headers = {
                "Authorization": f"Bearer {HF_TOKEN}",
                "Content-Type": "application/json",
            }

            async with httpx.AsyncClient(timeout=60.0) as client:
                response = await client.post(
                    HF_ROUTER_URL,
                    headers=headers,
                    json=payload,
                )

            print(f"[AI] Hugging Face status: {response.status_code}")
            print(f"[AI] Hugging Face raw response: {response.text}")

            response.raise_for_status()

            try:
                data = response.json()
            except Exception as e:
                print(f"[AI] Failed to parse HF JSON: {e}")
                raise

            try:
                result = data["choices"][0]["message"]["content"]
                print("GENERATED:\n", result)
            except (KeyError, IndexError, TypeError) as e:
                print(f"[AI] Unexpected HF response format: {data}")
                raise RuntimeError("Unexpected Hugging Face response format") from e

            print("[AI] Hugging Face succeeded.")

            return result

        except httpx.HTTPStatusError as e:

            status = e.response.status_code

            print(f"[AI] Hugging Face HTTP error: {status}")

            # These are reasonable fallback conditions
            if status not in {402, 429, 500, 502, 503, 504}:
                raise

            print("[AI] Hugging Face unavailable. Falling back to OpenRouter...")

        except (httpx.TimeoutException, httpx.ConnectError) as e:

            print(f"[AI] Hugging Face connection error: {e}")
            print("[AI] Falling back to OpenRouter...")

        # -------------------------
        # 2. OpenRouter
        # -------------------------
        try:
            print("[AI] Trying OpenRouter...")

            payload = {
                "model": "openrouter/free",
                "messages": messages,
                "temperature": 0,
            }

            headers = {
                "Authorization": f"Bearer {OPENROUTER_API_KEY}",
                "Content-Type": "application/json",
            }

            async with httpx.AsyncClient(timeout=60.0) as client:
                response = await client.post(
                    OPENROUTER_URL,
                    headers=headers,
                    json=payload,
                )

            print(f"[AI] OpenRouter status: {response.status_code}")

            response.raise_for_status()

            data = response.json()

            result = data["choices"][0]["message"]["content"]

            print("[AI] OpenRouter RAW CONTENT:")
            print(repr(result))

            print("[AI] OpenRouter succeeded.")

            return result

        except httpx.HTTPStatusError as e:

            print(
                f"[AI] OpenRouter HTTP error: "
                f"{e.response.status_code}"
            )

            raise

        except Exception as e:

            print(f"[AI] OpenRouter failed: {e}")
            raise