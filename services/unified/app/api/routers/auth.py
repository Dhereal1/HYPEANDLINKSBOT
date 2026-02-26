from __future__ import annotations

from fastapi import APIRouter, HTTPException, Request
from fastapi.responses import Response

from app.config import settings
from app.forwarding.client import forward_post

router = APIRouter()


@router.post("/auth/telegram")
async def auth_telegram(request: Request) -> Response:
    if settings.auth_mode == "local":
        raise HTTPException(status_code=501, detail="UNIFIED_AUTH_MODE=local is not implemented yet")
    return await forward_post(request, f"{settings.bot_base_url}/auth/telegram")
