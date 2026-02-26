from __future__ import annotations

from fastapi import APIRouter, HTTPException, Request
from fastapi.responses import Response

from app.config import settings
from app.forwarding.client import forward_post

router = APIRouter()


@router.post("/rag/query")
async def rag_query(request: Request) -> Response:
    if settings.rag_mode == "local":
        raise HTTPException(status_code=501, detail="UNIFIED_RAG_MODE=local is not implemented yet")
    return await forward_post(request, f"{settings.rag_base_url}/query")


@router.post("/query")
async def rag_query_compat(request: Request) -> Response:
    return await rag_query(request)
