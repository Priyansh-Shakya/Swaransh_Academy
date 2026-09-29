from sparse_ai import Client, Message, Tool, Agent, State, Graph
from sparse_ai.client import Providers
from sparse_ai.graph import Node, START, END
from typing import Any
import asyncpg
import os

from app.features.ai_assistant.agent.agent_tools import get_tables_schema, sql_execute , get_admission_schema
from app.features.ai_assistant.sys_prompt import ADMIN_SYSTEM_PROMPT, STUDENT_GUEST_SYSTEM_PROMPT 


# ============================================================
# 1. SHARED MODEL CLIENT
#    This is the ONLY client that lives outside build_agent().
#    Reuse it across requests.
# ============================================================

#? CLIENT IS CREATED IN main.py




# ============================================================
# 4. SYSTEM PROMPTS
#    Static instructions live outside build_agent().
# ============================================================
#? In sys_prompt.py


# ============================================================
# 5. ROLE-AWARE SYSTEM PROMPT
#    Your existing build_system_prompt() can replace this.
# ============================================================

def build_system_prompt(role: str, name: str | None = None) -> str:
    """Build the targeted system prompt based on user role.

    - Admin: Direct access to DB/reporting persona, no basic academy FAQs.
    - Student/Guest: Guidance persona, admissions schema tool, course/app help.
    """
    normalized_role = (role or "guest").strip().lower()
    user_name = name.strip() if name and name.strip() else "User"

    # Context block informing Sargam who she is speaking with
    user_context = f"""
Current User Context:
- Name: {user_name}
- Role: {normalized_role}
Rule: Address {user_name} naturally when appropriate; do not repeat their name robotically in every turn.
"""

    if normalized_role == "admin":
        base_prompt = ADMIN_SYSTEM_PROMPT
    else:
        # Defaults to student/guest prompt for "student", "guest", or unauthenticated roles
        base_prompt = STUDENT_GUEST_SYSTEM_PROMPT

    return f"{base_prompt.strip()}\n\n{user_context.strip()}"

# ============================================================
# 6. GRAPH
#    Built once and reused.
#    This reproduces your notebook's chat -> tool -> chat flow.
# ============================================================

def route_chat(state):
    """
    Route to tools when the LLM produced tool calls.
    Otherwise finish the request.
    """

    if state.tool_calls:
        return "tool"

    return END


graph = Graph()

graph.graph_builder(
    nodes={
        "chat": Node.llm_call(),
        "tool": Node.tool_exec(),
    },

    edges=[
        (START, "chat"),
        ("tool", "chat"),
    ],

    routers=[
        (
            "chat",
            route_chat,
            {
                "Tool_Call": "tool",
                "No_Tool": "END",
            },
        )
    ],
)


# ============================================================
# 7. BUILD AGENT
#    This is now intentionally small and clean.
#
#    The only request-specific responsibilities are:
#      - system prompt
#      - conversation history
#      - role-based tool access
#      - Agent construction
# ============================================================

def build_agent(query_history, role, db, name, client):

    system_prompt = build_system_prompt(role, name)

    messages = [Message.system(system_prompt)]

    for turn in query_history:
        if turn.role == "user":
            messages.append(Message.user(turn.content))
        else:
            messages.append(Message.assistant(turn.content))


    
    
    tools = [
        Tool(sql_execute),
        Tool(get_tables_schema),
    ] if role == "admin" else [Tool(get_admission_schema)]

    return Agent(
        client=client,
        messages=messages,
        state=State(messages=messages),
        graph=graph,
        auto_handle_interrupts=True,
        tools=tools,
        logging=True,
    )
