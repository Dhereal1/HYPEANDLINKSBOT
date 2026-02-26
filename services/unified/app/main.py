from __future__ import annotations

from fastapi import FastAPI

from app.api.routers.ai import router as ai_router
from app.api.routers.auth import router as auth_router
from app.api.routers.rag import router as rag_router
from app.config import settings
from app.health import health_payload

app = FastAPI(title="HyperlinksSpace Unified Service")

app.include_router(auth_router)
app.include_router(ai_router)
app.include_router(rag_router)


@app.get("/health")
async def health() -> dict[str, object]:
    return health_payload()


@app.get("/ready")
async def ready() -> dict[str, object]:
    return {
        "status": "ready",
        "service": "unified",
        "mode": settings.unified_mode,
    }
