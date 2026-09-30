import re
from typing import TypedDict


class SQLValidationResult(TypedDict):
    valid: bool
    command: str | None
    error: str | None


def _has_unconditional_where(where: str) -> bool:
    """
    Only detect obvious tautologies.

    Intentionally NOT a SQL semantic analyzer.
    Everything else is allowed.
    """

    # Normalize whitespace and case.
    condition = re.sub(r"\s+", " ", where.strip()).lower()

    # Remove surrounding parentheses.
    while (
        condition.startswith("(")
        and condition.endswith(")")
    ):
        condition = condition[1:-1].strip()

    # ---------------------------------------------------------
    # Direct unconditional conditions
    # ---------------------------------------------------------

    obvious_true = {
        "true",
        "1=1",
        "1 = 1",
        "0=0",
        "0 = 0",
        "true=true",
        "true = true",
    }

    if condition in obvious_true:
        return True

    # ---------------------------------------------------------
    # Obvious tautology anywhere in an OR condition.
    #
    # WHERE id = 123 OR 1=1
    # WHERE name = 'bob' OR TRUE
    # ---------------------------------------------------------

    if re.search(
        r"\bor\b\s*(?:true|1\s*=\s*1|0\s*=\s*0|true\s*=\s*true)\b",
        condition,
        re.IGNORECASE,
    ):
        return True

    # Also catch:
    #
    # WHERE 1=1 OR ...
    # WHERE TRUE OR ...
    #

    if re.search(
        r"(?:^|\bor\b)\s*(?:true|1\s*=\s*1|0\s*=\s*0|true\s*=\s*true)\b",
        condition,
        re.IGNORECASE,
    ):
        return True

    return False


def validate_sql(sql: str) -> SQLValidationResult:
    """
    Lightweight SQL guardrail.

    Rules:
    - Everything is allowed by default.
    - UPDATE requires WHERE.
    - DELETE requires WHERE.
    - UPDATE/DELETE reject obvious unconditional WHERE clauses.
    """

    if not isinstance(sql, str):
        return {
            "valid": False,
            "command": None,
            "error": "SQL must be a string",
        }

    sql = sql.strip()

    if not sql:
        return {
            "valid": False,
            "command": None,
            "error": "SQL cannot be empty",
        }

    # ---------------------------------------------------------
    # Identify command only.
    # ---------------------------------------------------------

    match = re.match(
        r"^\s*(SELECT|INSERT|UPDATE|DELETE)\b",
        sql,
        re.IGNORECASE,
    )

    if not match:
        return {
            "valid": False,
            "command": None,
            "error": (
                "Only SELECT, INSERT, UPDATE and DELETE are allowed"
            ),
        }

    command = match.group(1).upper()

    # SELECT / INSERT:
    # Don't overthink them. Let them pass.
    if command in {"SELECT", "INSERT"}:
        return {
            "valid": True,
            "command": command,
            "error": None,
        }

    # ---------------------------------------------------------
    # UPDATE / DELETE require WHERE.
    # ---------------------------------------------------------

    where_match = re.search(
        r"\bWHERE\b\s*(.*)$",
        sql,
        re.IGNORECASE | re.DOTALL,
    )

    if not where_match:
        return {
            "valid": False,
            "command": command,
            "error": (
                f"{command} statements must contain a WHERE clause"
            ),
        }

    where = where_match.group(1).strip()

    if not where:
        return {
            "valid": False,
            "command": command,
            "error": "WHERE clause cannot be empty",
        }

    # ---------------------------------------------------------
    # Only reject obvious "everything" predicates.
    # ---------------------------------------------------------

    if _has_unconditional_where(where):
        return {
            "valid": False,
            "command": command,
            "error": (
                f"{command} WHERE clause appears to be unconditional"
            ),
        }

    return {
        "valid": True,
        "command": command,
        "error": None,
    }
