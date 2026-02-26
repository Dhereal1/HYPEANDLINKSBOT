from __future__ import annotations

from typing import Any

import httpx
from fastapi import HTTPException, Request
from fastapi.responses import JSONResponse, Response

from app.config import settings


def _forward_headers(request: Request) -> dict[str, str]:
    headers: dict[str, str] = {}
    content_type = request.headers.get("content-type")
    if content_type:
        headers["content-type"] = content_type

    if "x-api-key" in request.headers:
        headers["x-api-key"] = request.headers["x-api-key"]
    elif settings.inner_calls_key:
        headers["x-api-key"] = settings.inner_calls_key

    return headers


async def forward_post(request: Request, upstream_url: str) -> Response:
    payload: Any = await request.body()
    headers = _forward_headers(request)

    timeout = httpx.Timeout(
        settings.forward_timeout_seconds,
        connect=settings.forward_connect_timeout_seconds,
    )

    try:
        async with httpx.AsyncClient(timeout=timeout) as client:
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
