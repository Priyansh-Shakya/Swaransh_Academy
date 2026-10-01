from enum import Enum

from pydantic import AnyUrl


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

def _format_agent_status(state: str | object) -> str:
    state_str = str(state)

    # 1. Schema check
    if "get_tables_schema" in state_str:
        match = re.search(r"tables['\"]?\s*:\s*\[?['\"]([^'\"\]]+)", state_str)
        table = match.group(1) if match else "database"
        return f"Checking {table} table schema..."

    # 2. SQL query execution
    if "sql_execute" in state_str:
        return "Querying database..."

    # 3. Generic ToolCall fallback
    match = re.search(r"name=['\"]([^'\"]+)['\"]", state_str)
    if match:
        clean_name = match.group(1).replace("_", " ")
        return f"Executing {clean_name}..."

    # 4. If it's already a clean string like "[STATUS]: searching..."
    clean = re.sub(r"^\[STATUS\]:?\s*", "", state_str).strip()
    return clean if clean else "Processing request..."