

import json

import httpx
from app.features.ai_assistant.agent.query_validator import validate_sql
from app.features.ai_assistant.config import HF_MODEL, HF_ROUTER_URL, HF_TOKEN
from app.features.ai_assistant.sys_prompt import GENERATOR_PROMPT


def build_sql_messages(user_query: str) -> list[dict]:
    return [
        {
            "role": "system",
            "content": GENERATOR_PROMPT,
        },
        {
            "role": "user",
            "content": user_query,
        },
    ]

async def generate_sql(user_query: str):
    payload = {
        "model": HF_MODEL,
        "messages": build_sql_messages(user_query),
        "response_format": {
        "type": "json_object"
    },
        "stream": False
    }

    headers = {
        "Authorization": f"Bearer {HF_TOKEN}",
        "Content-Type": "application/json"
    }

    async with httpx.AsyncClient(timeout=60.0) as client:
        response = await client.post(
            HF_ROUTER_URL,
            headers=headers,

            json=payload
        )

        response.raise_for_status()

        data = response.json()

        response  =  data["choices"][0]["message"]["content"]
        print("SQL GENERATOR FUNCTION:\n", response)
        return response




async def extract_query(sql: dict, db):
    sql = json.loads(sql)
    if sql["type"] == "sql":
        query = sql["query"]
        if not validate_sql(query):
            return "SQL Query Rejected: query failed safety Moderation check."
        result = await db.fetch(query)
        return [dict(row) for row in result] if result else "No data found"

    elif sql["type"] == "reject":
        return "Potentially Harmful Request, Cannot fulfill request."

    elif sql["type"] == "chat":
            return "This is a Chat query , No SQL Generated."

    elif sql["type"] == "clarification":
        return f"Need Clarification on request, Did not execute SQL and not fetched any data.\n{sql['message']}"