

import json

from app.features.ai_assistant.agent.normalize_query import normalize_write_query
from app.features.ai_assistant.agent.query_validator import validate_sql
from app.features.ai_assistant.model import ChatMessage
from app.features.ai_assistant.service.sql_service import AIServiceSql
from app.features.extra_config.prompts import get_prompt

#* Instanciate Class.
ai_service = AIServiceSql()


async def build_sql_messages(
    user_query: str,
    history: list[ChatMessage],
    db,
) -> list[dict]:

    generator_prompt = await get_prompt("generator_prompt", db)

    messages = [
        {
            "role": "system",
            "content": generator_prompt,
        }
    ]


    for message in history:
        messages.append(
            {
                "role": message.role,
                "content": message.content,
            }
        )

    messages.append(
        {
            "role": "user",
            "content": user_query,
        }
    )

    return messages

async def generate_sql(user_query: str, history, db):
    _messages = await build_sql_messages(user_query, history , db)
    return await ai_service.generate_sql(
        messages= _messages
    )



async def extract_query(sql_input: str | dict, db) -> tuple[any, str | None]:
    """
    Returns a tuple of (data_or_message, executed_sql_query)
    """
    sql = json.loads(sql_input) if isinstance(sql_input, str) else sql_input
    query_type = sql.get("type")

    if query_type == "sql":
        raw_query = sql.get("query", "")
        if not validate_sql(raw_query):
            return "SQL Query Rejected: query failed safety Moderation check.", raw_query

        # normalize: strips any LLM-added RETURNING, re-appends a safe one for writes
        query, op, table = normalize_write_query(raw_query)
        
        try:
            result = await db.fetch(query)
        except Exception as e:  # noqa: BLE001
            # Don't let DB errors break the overall flow
            return (
                f"SQL Query Execution Failed: {e!s}",
                query,
            )
        rows = [dict(row) for row in result] if result else []

        if op:  # INSERT / UPDATE / DELETE
            data = {
                "operation": op,
                "table": table,
                "affected_rows": len(rows),
                "records": rows,          # already column-limited by normalize step
            }
            if not rows:
                # explicit zero-match signal so stream AI doesn't assume success
                data["note"] = "No matching rows were affected by this operation."
        else:  # SELECT
            data = rows if rows else "No data found"

        return data, query   # return the *executed* query, not the raw one, for logging/debugging

    elif query_type == "reject":
        return "Potentially Harmful Request, Cannot fulfill request.", None

    elif query_type == "chat":
        return "This is a Chat query , No SQL Generated.", None

    elif query_type == "clarification":
        msg = sql.get('message', '')
        return f"Need Clarification on request, Did not execute SQL and not fetched any data.\n{msg}", None

    return "Unknown response type.", None