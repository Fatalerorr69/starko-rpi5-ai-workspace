# web_gui/core/ai_engine.py
"""Jednoduchý, bezpečný wrapper AI modu.
Design: hybrid-ready (lokálni LLM + cloud fallback) — plug-and-play.
"""
from typing import Optional, Dict, Any


class AIEngine:
def __init__(self, local_model_path: Optional[str] = None, api_key: Optional[str] = None):
self.local_model_path = local_model_path
self.api_key = api_key
self.mode = "local" if local_model_path else "api"


def ping(self) -> Dict[str, Any]:
return {"mode": self.mode, "local_model": self.local_model_path is not None}


def generate(self, prompt: str, max_tokens: int = 512) -> Dict[str, str]:
"""Vrati jednoduchou odpoved (stub). Implementuj volani lokálního modelu nebo OpenAI zde."""
# bezpečnost: nikdy nespoustej shell prikazy bez explicitniho povoleni
return {"response": f"[AI STUB] Received prompt of length {len(prompt)}"}


# pridat metody pro analyzu logu, vykonavani bezpecnych prikazu, atd.
