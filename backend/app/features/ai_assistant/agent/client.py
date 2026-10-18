from sparse_ai import Client
from sparse_ai.client import Providers
import os


def build_client():
    client = Client(
            api_key=os.getenv("GROQ_API_KEY"),
            model=os.getenv("MODEL", "openai/gpt-oss-20b"),
            provider=Providers.GROQ,
        )

    return client