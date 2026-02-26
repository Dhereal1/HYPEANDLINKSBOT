from __future__ import annotations

from fastapi import APIRouter, HTTPException, Request
from fastapi.responses import Response

from app.config import settings
from app.forwarding.client import forward_post

router = APIRouter()


@router.post("/ai/chat")
async def ai_chat(request: Request) -> Response:
    if settings.ai_mode == "local":
        raise HTTPException(status_code=501, detail="UNIFIED_AI_MODE=local is not implemented yet")
    return await forward_post(request, f"{settings.ai_base_url}/api/chat")


@router.post("/api/chat")
async def ai_chat_compat(request: Request) -> Response:
    return await ai_chat(request)
