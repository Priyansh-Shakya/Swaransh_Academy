async def get_prompt(key: str, db):
    row = await db.fetchrow(
        "SELECT value FROM config WHERE key = $1",
        key,
    )

    if row is None:
        raise ValueError(f"Config key not found: {key}")

    return row["value"]