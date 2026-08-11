import os

import asyncpg

pool = None

async def init_db():
    DATABASE_URL = os.getenv("DATABASE_URL")

    print("Database URL:", DATABASE_URL)
    global pool
    pool = await asyncpg.create_pool(DATABASE_URL, statement_cache_size=0)

async def close_db():
    await pool.close()

async def get_db():
    async with pool.acquire() as conn:
        yield conn

    