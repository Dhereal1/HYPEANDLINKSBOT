from __future__ import annotations

import os
from dataclasses import dataclass

_VALID_MODES = {"forward", "local", "shadow"}


def _normalize_url(value: str, default: str) -> str:
    raw = (value or default).strip()
    if raw and not raw.startswith(("http://", "https://")):
        raw = f"https://{raw}"
    return raw.rstrip("/")


def _mode(value: str, default: str) -> str:
    candidate = (value or default).strip().lower()
    if candidate not in _VALID_MODES:
        return default
    return candidate


@dataclass(frozen=True)
class Settings:
    unified_mode: str
    auth_mode: str
    ai_mode: str
    rag_mode: str
    wallet_mode: str
    tasks_mode: str
    feed_mode: str
    forward_timeout_seconds: float
    forward_connect_timeout_seconds: float
    bot_base_url: str
    ai_base_url: str
    rag_base_url: str
    inner_calls_key: str


def load_settings() -> Settings:
    unified_mode = _mode(os.getenv("UNIFIED_MODE", "forward"), "forward")
    return Settings(
        unified_mode=unified_mode,
        auth_mode=_mode(os.getenv("UNIFIED_AUTH_MODE", ""), unified_mode),
        ai_mode=_mode(os.getenv("UNIFIED_AI_MODE", ""), unified_mode),
        rag_mode=_mode(os.getenv("UNIFIED_RAG_MODE", ""), unified_mode),
        wallet_mode=_mode(os.getenv("UNIFIED_WALLET_MODE", ""), unified_mode),
        tasks_mode=_mode(os.getenv("UNIFIED_TASKS_MODE", ""), unified_mode),
        feed_mode=_mode(os.getenv("UNIFIED_FEED_MODE", ""), unified_mode),
        forward_timeout_seconds=float(os.getenv("UNIFIED_FORWARD_TIMEOUT_SECONDS", "30")),
        forward_connect_timeout_seconds=float(os.getenv("UNIFIED_FORWARD_CONNECT_TIMEOUT_SECONDS", "5")),
        bot_base_url=_normalize_url(os.getenv("BOT_BASE_URL", ""), "http://127.0.0.1:8080"),
        ai_base_url=_normalize_url(os.getenv("AI_BASE_URL", ""), "http://127.0.0.1:8000"),
        rag_base_url=_normalize_url(os.getenv("RAG_BASE_URL", ""), "http://127.0.0.1:8001"),
        inner_calls_key=(os.getenv("INNER_CALLS_KEY") or os.getenv("API_KEY") or "").strip(),
    )


settings = load_settings()
