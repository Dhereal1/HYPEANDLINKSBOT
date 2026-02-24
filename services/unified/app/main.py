from __future__ import annotations

import os
from typing import Any, Dict

import httpx
from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import JSONResponse, Response

app = FastAPI(title="HyperlinksSpace Unified Service")


def _normalize_url(value: str, default: str) -> str:
    raw = (value or default).strip()
    if raw and not raw.startswith(("http://", "https://")):
        raw = f"https://{raw}"
    return raw.rstrip("/")


UNIFIED_MODE = (os.getenv("UNIFIED_MODE", "forward") or "forward").strip().lower()
FORWARD_TIMEOUT_SECONDS = float(os.getenv("UNIFIED_FORWARD_TIMEOUT_SECONDS", "30"))
BOT_BASE_URL = _normalize_url(os.getenv("BOT_BASE_URL", ""), "http://127.0.0.1:8080")
AI_BASE_URL = _normalize_url(os.getenv("AI_BASE_URL", ""), "http://127.0.0.1:8000")
RAG_BASE_URL = _normalize_url(os.getenv("RAG_BASE_URL", ""), "http://127.0.0.1:8001")
INNER_CALLS_KEY = (os.getenv("INNER_CALLS_KEY") or os.getenv("API_KEY") or "").strip()


def _forward_headers(incoming: Request) -> Dict[str, str]:
    headers: Dict[str, str] = {}
    content_type = incoming.headers.get("content-type")
    if content_type:
        headers["content-type"] = content_type
    if INNER_CALLS_KEY and "x-api-key" not in incoming.headers:
        headers["x-api-key"] = INNER_CALLS_KEY
    elif "x-api-key" in incoming.headers:
        headers["x-api-key"] = incoming.headers["x-api-key"]
    return headers


async def _forward_post(request: Request, upstream_url: str) -> Response:
    payload: Any = await request.body()
    headers = _forward_headers(request)
    try:
        async with httpx.AsyncClient(timeout=FORWARD_TIMEOUT_SECONDS) as client:
            upstream = await client.post(upstream_url, content=payload, headers=headers)
    except httpx.TimeoutException as exc:
        raise HTTPException(status_code=504, detail=f"Upstream timeout: {exc}") from exc
    except httpx.HTTPError as exc:
        raise HTTPException(status_code=502, detail=f"Upstream request failed: {exc}") from exc

    content_type = upstream.headers.get("content-type", "")
    if "application/json" in content_type:
        return JSONResponse(status_code=upstream.status_code, content=upstream.json())
    return Response(
        content=upstream.content,
        status_code=upstream.status_code,
        media_type=content_type or None,
    )


@app.get("/health")
async def health() -> Dict[str, Any]:
    return {
        "status": "ok",
        "service": "unified",
        "mode": UNIFIED_MODE,
        "routes": {
            "auth_telegram": "/auth/telegram",
            "ai_chat": ["/ai/chat", "/api/chat"],
            "rag_query": ["/rag/query", "/query"],
        },
    }


@app.post("/auth/telegram")
async def auth_telegram(request: Request) -> Response:
    if UNIFIED_MODE != "forward":
        raise HTTPException(status_code=501, detail="UNIFIED_MODE=local is not implemented yet")
    return await _forward_post(request, f"{BOT_BASE_URL}/auth/telegram")


@app.post("/ai/chat")
async def ai_chat(request: Request) -> Response:
    if UNIFIED_MODE != "forward":
        raise HTTPException(status_code=501, detail="UNIFIED_MODE=local is not implemented yet")
    return await _forward_post(request, f"{AI_BASE_URL}/api/chat")


@app.post("/api/chat")
async def api_chat_compat(request: Request) -> Response:
    return await ai_chat(request)


@app.post("/rag/query")
async def rag_query(request: Request) -> Response:
    if UNIFIED_MODE != "forward":
        raise HTTPException(status_code=501, detail="UNIFIED_MODE=local is not implemented yet")
    return await _forward_post(request, f"{RAG_BASE_URL}/query")


@app.post("/query")
async def rag_query_compat(request: Request) -> Response:
    return await rag_query(request)
