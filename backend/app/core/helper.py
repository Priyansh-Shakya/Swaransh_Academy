from enum import Enum

from pydantic import AnyUrl
from sparse_ai import StatusEvent


def convert_enums_to_values(data):
    """
    This function takes a dictionary and converts any Enum values to their corresponding string values.
    """
    for key, val in data.items():
        if isinstance(val, Enum):
            data[key] = val.value
        elif isinstance(val, AnyUrl):
            data[key] = str(val)
    return data


import json
import re

def _format_agent_status(event: StatusEvent) -> str:
    tool_name = getattr(event, "tool_name", "")
    detail = getattr(event, "detail", "")
    state_str = f"{tool_name} {detail}"

    # 1. Schema check
    if "get_tables_schema" in tool_name or "get_tables_schema" in state_str:
        match = re.search(r"tables['\"]?\s*:\s*\[?['\"]([^'\"\]]+)", state_str)
        table = match.group(1) if match else "database"
        return f"Checking {table} table schema..."

    # 2. SQL query execution
    if "sql_execute" in tool_name or "sql_execute" in state_str:
        return "Querying database..."

    # 3. Generic ToolCall fallback based on tool name
    if tool_name:
        clean_name = tool_name.replace("_", " ")
        return f"Executing {clean_name}..."

    # 4. Fallback to detail string if available
    clean = re.sub(r"^\[STATUS\]:?\s*", "", detail).strip()
    return clean if clean else "Processing request..."
