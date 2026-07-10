# app/core/env.py
from pathlib import Path

from dotenv import load_dotenv

load_dotenv(dotenv_path=Path(__file__).resolve().parent.parent / ".env")

placeholder = "So that RUFF doesnt remove any import which is not used in main , we will print this variable"