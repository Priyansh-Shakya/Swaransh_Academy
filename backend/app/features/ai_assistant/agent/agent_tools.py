# ============================================================
# 2. DATABASE LAYER
#    Kept completely outside build_agent().
# ============================================================

import os
from typing import Any

import asyncpg

from app.features.ai_assistant.agent.sql_validator import validate_sql


DATABASE_URL = os.getenv("DATABASE_URL")

_pool: asyncpg.Pool | None = None


async def get_db() -> asyncpg.Pool:
    """Create/reuse the shared PostgreSQL connection pool."""

    global _pool

    if _pool is None:
        _pool = await asyncpg.create_pool(
            dsn=DATABASE_URL,
            min_size=1,
            max_size=10,
            statement_cache_size=0,
        )

    return _pool


async def sql_execute(query: str) -> list[dict[str, Any]]:
    """
    Execute SQL against PostgreSQL and return normal dictionaries.
    """

    validation = validate_sql(query)

    if validation["valid"]:
        pool = await get_db()

        async with pool.acquire() as conn:
            rows = await conn.fetch(query)
            return [dict(row) for row in rows]

    error = validation["error"] or "SQL query failed validation."

    print(error)
    return error



async def close_db():
    """Close the shared database pool."""

    global _pool

    if _pool is not None:
        await _pool.close()
        _pool = None



# ============================================================
# 3. DATABASE SCHEMA TOOL
#    Kept outside build_agent().
# ============================================================

def get_tables_schema(tables: list[str]):
    """
    Return schema information only for the requested tables,
    including relevant enums and relationships.
    Tables to search from ['students' , 'admissions' , 'courses' , 'payment' , 'users']
    """

    schemas = {
        "enums": {
            "user_role": "{guest, student, admin}",
            "department": "{music, dance, acting, music_video_production, other}",
            "learning_mode": "{online, offline, hybrid}",
            "admission_type": "{regular, band_training, summer_camp, custom}",
            "course_tag": "{vocal, instrumental}",
            "batch": "{morning, evening}",
            "education_qualification": "{primary_school, high_school, bachelors, masters}",
            "fee_type": "{monthly, quarterly, half_yearly, yearly}",
            "admission_status": "{pending, approved, declined}",
            "student_status": "{pending_payment, active, inactive}",
            "student_gender": "{male, female, non_binary}",
            "payment_type": "{admission, monthly, quarterly, half_yearly, yearly}",
            "payment_cat": "{fee, admission, other}",
            "payment_mode": "{cash, upi, card, bank_transfer, other}",
            "payment_status": "{active, superseded}",
        },

        "enum_usage": {
            "users": ["user_role"],

            "students": [
                "admission_type",
                "learning_mode",
                "department",
                "batch",
                "education_qualification",
                "admission_status",
                "student_status",
                "student_gender",
                "fee_type",
            ],

            "payment": [
                "payment_type",
                "payment_mode",
                "payment_status",
                "payment_cat",
            ],

            "courses": [
                "learning_mode",
                "course_tag",
                "department",
            ],

            "admissions": [
                "admission_status",
                "student_gender",
                "education_qualification",
                "admission_type",
                "learning_mode",
                "department",
                "batch",
                "fee_type",
            ],
        },

        "users":
        """users(
            user_id*:uuid,
            user_name:text,
            role*:user_role,
            email*:text,
            fcm_token:text,
            created_at:timestamptz
        )""",

        "students":
        """students(
            id*:bigint,
            user_id:uuid->users.user_id,
            name*:text,
            admission_type*:admission_type,
            learning_mode*:learning_mode,
            department*:department,
            batch*:batch,
            education_qualification*:education_qualification,
            admission_status*:admission_status,
            status*:student_status,
            start_time*:time,
            end_time*:time,
            subject*:text,
            courses:text[],
            dob*:date,
            father_name*:text,
            gender:student_gender,
            address:text,
            religion:text,
            caste:text,
            scholar_no:text(unique),
            date_of_joining*:date,
            contact:text,
            email*:text,
            fees*:double precision,
            fee_type:fee_type,
            fee_paid_till:date,
            image_url:text,
            created_at:timestamptz,
            updated_at:timestamptz
        )""",

        "payment":
        """payment(
            id*:bigint,
            student_id*:bigint->students.id,
            payment_type*:payment_type,
            amount*:bigint,
            mode*:payment_mode,
            txn_ref:text,
            paid_on:timestamptz,
            status:payment_status,
            superseded_by:bigint->payment.id,
            payment_category*:payment_cat,
            isactive:boolean
        )""",

        "courses":
        """courses(
            id*:bigint,
            course_name*:text,
            duration:text,
            fees*:bigint,
            mode:learning_mode,
            created_at:timestamptz,
            updated_at:timestamptz,
            tag*:course_tag,
            maps_to_department:department,
            maps_to_subject:text,
            image_url:text
        )""",

        "admissions":
        """admissions(
            id*:bigint,
            user_id:uuid->users.user_id,
            status*:admission_status,
            name*:text,
            dob:date,
            gender:student_gender,
            father_name:text,
            education_qualification:education_qualification,
            contact:text,
            email:text,
            address:text,
            religion:text,
            caste:text,
            admission_type:admission_type,
            learning_mode:learning_mode,
            department:department,
            batch:batch,
            start_time:time,
            end_time:time,
            subject:text,
            courses:text[],
            fees:numeric(10,2),
            fee_type:fee_type,
            created_at:timestamptz,
            updated_at:timestamptz,
            image_url:text
        )""",

        "relationships": [
            ("admissions", "user_id -> users.user_id (SET NULL)"),
            ("students", "user_id -> users.user_id (SET NULL)"),
            ("payment", "student_id -> students.id (CASCADE)"),
            ("payment", "superseded_by -> payment.id (SET NULL)"),
        ],
    }

    requested = set(tables)

    result = {}

    # --------------------------------------------------------
    # Requested table schemas
    # --------------------------------------------------------

    for table in requested:
        if table in schemas:
            result[table] = schemas[table]

    # --------------------------------------------------------
    # Only enums used by requested tables
    # --------------------------------------------------------

    enum_names = set()

    for table in requested:
        enum_names.update(
            schemas["enum_usage"].get(table, [])
        )

    result["enums"] = "\n".join(
        f"{name} = {schemas['enums'][name]}"
        for name in sorted(enum_names)
    )

    # --------------------------------------------------------
    # Only relationships relevant to requested tables
    # --------------------------------------------------------

    relationships = []

    for source_table, relationship in schemas["relationships"]:

        target_table = (
            relationship
            .split("->")[1]
            .split(".")[0]
            .strip()
        )

        if (
            source_table in requested
            or target_table in requested
        ):
            relationships.append(
                f"{source_table}.{relationship}"
            )

    result["relationships"] = "\n".join(
        relationships
    )

    return result



#* ----------------- Student/Guest Tool ----------------------------------

def get_admission_schema():
    """Returns valid choices and data formats for the admission form."""
    return {
        "text_fields": [
            "name*",
            "father_name",
            "contact",
            "email",
            "address",
            "subject",
            "religion",
            "caste",
            "image_url",
        ],
        "format_fields": {
            "dob": "YYYY-MM-DD",
            "start_time": "HH:MM",
            "end_time": "HH:MM",
            "courses": "list[text]",
        },
        "enums": {
            "gender": ["male", "female", "non_binary"],
            "education_qualification": [
                "primary_school",
                "high_school",
                "bachelors",
                "masters",
            ],
            "admission_type": [
                "regular",
                "band_training",
                "summer_camp",
                "custom",
            ],
            "learning_mode": ["online", "offline", "hybrid"],
            "department": [
                "music",
                "dance",
                "acting",
                "music_video_production",
                "other",
            ],
            "batch": ["morning", "evening"],
            "fee_type": ["monthly", "quarterly", "half_yearly", "yearly"],
        },
    }

