from __future__ import annotations

from typing import Any

from app.config import settings


def health_payload() -> dict[str, Any]:
    return {
        "status": "ok",
        "service": "unified",
        "mode": settings.unified_mode,
        "route_modes": {
            "auth": settings.auth_mode,
            "ai": settings.ai_mode,
            "rag": settings.rag_mode,
            "wallet": settings.wallet_mode,
            "tasks": settings.tasks_mode,
            "feed": settings.feed_mode,
        },
        "routes": {
            "auth_telegram": "/auth/telegram",
            "ai_chat": ["/ai/chat", "/api/chat"],
            "rag_query": ["/rag/query", "/query"],
        },
    }
