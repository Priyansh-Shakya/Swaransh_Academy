import os

import requests
from dotenv import load_dotenv

load_dotenv()
token = os.getenv("HF_TOKEN")

url = "https://router.huggingface.co/v1/chat/completions"
headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
payload = {
    "model": "deepseek-ai/DeepSeek-V3",
    "messages": [{"role": "user", "content": "hello"}]
}

r = requests.post(url, headers=headers, json=payload)
print("---------------------------------------- Test AI Assistant File Running ---------------------------------------------------------")
print(r.status_code)
print(r.text)