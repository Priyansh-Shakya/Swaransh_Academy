import os

from dotenv import load_dotenv

load_dotenv()

HF_TOKEN = os.getenv("HF_TOKEN")
HF_ROUTER_URL = "https://router.huggingface.co/v1/chat/completions"

HF_MODEL = "deepseek-ai/DeepSeek-R1-Distill-Qwen-7B"      #? CHANGED FROM "deepseek-ai/DeepSeek-V3"

HF_SQL_MODEL ="Qwen/Qwen2.5-Coder-7B-Instruct"

if not HF_TOKEN and not HF_ROUTER_URL:
    raise RuntimeError("HF_TOKEN is not set in environment")
else:
    print("Everything is Good to go (Config OK)")
    