from enum import Enum

from fastapi import Request


def get_models(request: Request):
    return request.app.state.vec, request.app.state.clf

class Intent(Enum):
    chat = "Chat"
    query = "Query"


def intent_router(query: str, vec , clf) -> Intent:
    X = vec.transform([query])
    pred = clf.predict(X)[0]
    return Intent.query if pred == "sql" else Intent.chat