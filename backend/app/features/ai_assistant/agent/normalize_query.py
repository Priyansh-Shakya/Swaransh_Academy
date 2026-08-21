import re

BASE_IDENTIFIERS = {
    "students": {"id", "scholar_no", "name", "status"},
    "admissions": {"id", "name", "status", "admission_status"},
    "payment": {"id", "student_id", "amount", "status"},
    "courses": {"id", "course_name"},
    "users": {"user_id", "user_name", "role"},
}


def _split_top_level(s: str) -> list[str]:
    """Split on commas not inside (), [], or quotes."""
    parts, depth, buf, in_str = [], 0, "", False
    prev_ch = ""

    for ch in s:
        # Handle quoted strings and escaped quotes (e.g. 'O\'Connor')
        if ch == "'" and prev_ch != "\\":
            in_str = not in_str
        elif ch in "([" and not in_str:
            depth += 1
        elif ch in ")]" and not in_str:
            depth -= 1

        if ch == "," and depth == 0 and not in_str:
            parts.append(buf)
            buf = ""
        else:
            buf += ch
        prev_ch = ch

    if buf.strip():
        parts.append(buf)
    return parts


def extract_touched_columns(query: str, op: str) -> set[str]:
    if op == "INSERT":
        m = re.search(r"INSERT\s+INTO\s+\w+\s*\(([^)]+)\)", query, re.IGNORECASE)
        return {c.strip().lower() for c in m.group(1).split(",")} if m else set()

    if op == "UPDATE":
        m = re.search(
            r"\bSET\b(.*?)(?:\bWHERE\b|$)", query, re.IGNORECASE | re.DOTALL
        )
        if not m:
            return set()
        cols = set()
        for part in _split_top_level(m.group(1)):
            col = re.match(r"\s*([a-zA-Z_]+)\s*=", part)
            if col:
                cols.add(col.group(1).lower())
        return cols

    return set()  # DELETE operations only use base identifiers


def normalize_write_query(query: str) -> tuple[str, str | None, str | None]:
    q = query.strip().rstrip(";")
    op_match = re.match(r"^\s*(INSERT|UPDATE|DELETE)\b", q, re.IGNORECASE)
    if not op_match:
        return q, None, None  # SELECT — untouched

    op = op_match.group(1).upper()
    q = re.sub(r"\bRETURNING\b.*$", "", q, flags=re.IGNORECASE | re.DOTALL).strip()

    table_match = re.search(r"(?:INTO|UPDATE|FROM)\s+([a-zA-Z_]+)", q, re.IGNORECASE)
    table = table_match.group(1).lower() if table_match else None

    cols = BASE_IDENTIFIERS.get(table, set()) | extract_touched_columns(q, op)
    col_str = ", ".join(sorted(cols)) if cols else "*"

    return f"{q} RETURNING {col_str}", op, table