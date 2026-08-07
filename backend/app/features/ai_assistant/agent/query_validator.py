import sqlparse
from sqlparse.sql import Function, Identifier, IdentifierList
from sqlparse.tokens import DML, Keyword

ALLOWED_TABLES = {"courses", "students", "admissions", "users", "payment"}

FORBIDDEN_STATEMENT_TYPES = {
    "DROP", "TRUNCATE", "ALTER", "DELETE", "GRANT", "REVOKE",
    "CREATE", "MERGE", "EXECUTE", "CALL",
}

# Postgres set-returning functions that can appear after FROM/JOIN but aren't tables
KNOWN_FUNCTIONS = {
    "unnest", "generate_series", "jsonb_each", "jsonb_array_elements",
    "json_each", "regexp_split_to_table", "now", "count", "sum", "avg",
    "max", "min", "coalesce",
}


def _split_statements(query: str):
    statements = [s for s in sqlparse.parse(query) if s.token_first(skip_cm=True)]
    return statements


def _get_statement_type(stmt) -> str:
    # DML token covers SELECT/INSERT/UPDATE/DELETE
    for token in stmt.tokens:
        if token.ttype is DML:
            return token.value.upper()
        if token.ttype is Keyword and token.value.upper() in FORBIDDEN_STATEMENT_TYPES:
            return token.value.upper()
    return ""


def _extract_tables(stmt) -> set[str]:
    """
    Walk tokens; after FROM/JOIN/INTO/UPDATE keywords, the next
    meaningful token is the table reference (or a function call,
    which we filter out separately).
    """
    tables = set()
    tokens = [t for t in stmt.flatten()]  # flatten nested groups for simpler scanning

    # Re-parse at group level (not fully flattened) so we can detect Function nodes
    def walk(tokens_list):
        trigger = False
        for tok in tokens_list:
            if trigger:
                if isinstance(tok, Function):
                    # Ambiguous node: could be a real function call like unnest(courses),
                    # OR a table with a column list like `students (name)` for INSERT.
                    # Extract the name either way; KNOWN_FUNCTIONS filters out the former.
                    name = tok.get_real_name()
                    if name:
                        tables.add(name.lower())
                    trigger = False
                    continue
                if isinstance(tok, IdentifierList):
                    for ident in tok.get_identifiers():
                        name = ident.get_real_name()
                        if name:
                            tables.add(name.lower())
                    trigger = False
                    continue
                if isinstance(tok, Identifier):
                    name = tok.get_real_name()
                    if name:
                        tables.add(name.lower())
                    trigger = False
                    continue
                if tok.ttype is None:
                    # group we don't recognize, skip
                    trigger = False
                    continue
                if not tok.is_whitespace:
                    trigger = False
                continue

            if tok.ttype in (Keyword, DML) and tok.value.upper() in ("FROM", "JOIN", "INTO", "UPDATE"):
                trigger = True

            # Recurse into sub-groups (subqueries, parens, etc.) EXCEPT Function
            # nodes. A function's own arguments can contain a FROM keyword that
            # means something else entirely (e.g. EXTRACT(YEAR FROM AGE(dob)),
            # SUBSTRING(str FROM 1 FOR 3), TRIM(chars FROM str)) — recursing in
            # would misread that as a table clause. Real subqueries used as
            # function args are plain Parenthesis nodes (no name precedes them),
            # not Function nodes, so they still get recursed correctly.
            if hasattr(tok, "tokens") and not isinstance(tok, Function):
                walk(tok.tokens)

    walk(stmt.tokens)
    return tables


def validate_sql(query: str) -> bool:
    if not query or not query.strip():
        return False

    statements = _split_statements(query)

    # ---- exactly one real statement ----
    if len(statements) != 1:
        return False

    stmt = statements[0]
    raw = str(stmt)

    # ---- block comments (sqlparse keeps them as tokens, but double check raw) ----
    if "--" in raw or "/*" in raw:
        return False

    stmt_type = _get_statement_type(stmt)

    if stmt_type in FORBIDDEN_STATEMENT_TYPES or stmt_type == "":
        return False

    if stmt_type not in ("SELECT", "INSERT", "UPDATE"):
        return False

    # ---- UPDATE must have WHERE ----
    if stmt_type == "UPDATE":
        has_where = any(
            isinstance(tok, sqlparse.sql.Where) for tok in stmt.tokens
        )
        if not has_where:
            return False

    # ---- table whitelist ----
    tables = _extract_tables(stmt)
    tables -= KNOWN_FUNCTIONS  # safety net in case a function slips through as Identifier

    if not tables:
        return stmt_type == "SELECT"  # e.g. SELECT NOW(), SELECT 1

    return tables.issubset(ALLOWED_TABLES)


# ---- quick tests ----
if __name__ == "__main__":
    tests = [
        ("SELECT COUNT(*) FROM students WHERE subject ILIKE '%guitar%' OR EXISTS (SELECT 1 FROM unnest(courses) AS course WHERE course ILIKE '%guitar%');", True),
        ("SELECT * FROM students", True),
        ("DROP TABLE students", False),
        ("SELECT * FROM students; DROP TABLE students;", False),
        ("UPDATE students SET fee = 0", False),  # no WHERE
        ("UPDATE students SET fee = 0 WHERE id = 1", True),
        ("SELECT * FROM staff", False),  # not in allowlist
        ("SELECT NOW()", True),
        ("SELECT * FROM students -- comment", False),
        ("INSERT INTO students (name) VALUES ('a')", True),
        ("SELECT * FROM students JOIN courses ON students.course_id = courses.id", True),
    ]

    for q, expected in tests:
        result = validate_sql(q)
        status = "OK" if result == expected else "FAIL"
        print(f"[{status}] expected={expected} got={result} :: {q[:70]}")