from enum import Enum


class Intent(Enum):
    chat = "Chat"
    query = "Query"

# If ANY of these appear, short-circuit to chat without calling generate_sql.
# Kept deliberately loose/high-recall for chat — false positives here just mean
# a chat-worthy query skips the SQL call, which is fine. False negatives (missed
# chat words) simply fall through to generate_sql's own "chat" classification.
CHAT_KEYWORDS = {
    # general advice / explanation
    "tips", "tip", "advice", "suggest", "suggestion", "suggestions",
    "method", "methods", "way", "ways", "how to", "kaise",
    "explain", "explanation", "why", "kyun", "क्यों",
    "help", "guide", "guidance", "recommend", "recommendation",

    # academy-culture / soft topics
    "comfortable", "discipline", "motivate", "motivation",
    "engage", "engagement", "improve", "improvement", "behtar", "बेहतर",
    "communication", "relationship", "environment", "culture",

    # entities that don't exist in your schema — always chat, never query
    "teacher", "teachers", "staff", "shikshak", "अध्यापक", "टीचर",

    # generic conversational openers
    "what do you think", "opinion", "should i", "salaah", "सलाह",
}

def intent_router(query: str) -> Intent:
    q = query.lower()

    if any(kw in q for kw in CHAT_KEYWORDS):
        print("Chat Query (keyword short-circuit)")
        return Intent.chat

    print("Ambiguous — deferring to generate_sql for classification")
    return Intent.query