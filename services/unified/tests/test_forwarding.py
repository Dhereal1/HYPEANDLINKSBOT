from fastapi.responses import JSONResponse
from fastapi.testclient import TestClient

from app.main import app
import app.api.routers.ai as ai_router


client = TestClient(app)


def test_ai_chat_forwards_in_default_mode(monkeypatch) -> None:
    called = {"url": None}

    async def fake_forward_post(request, upstream_url):
        called["url"] = upstream_url
        return JSONResponse({"ok": True}, status_code=200)

    monkeypatch.setattr(ai_router, "forward_post", fake_forward_post)

    response = client.post("/ai/chat", json={"message": "hello"})

    assert response.status_code == 200
    assert response.json() == {"ok": True}
    assert called["url"].endswith("/api/chat")


def test_api_chat_alias_uses_same_forward_path(monkeypatch) -> None:
    called = {"url": None}

    async def fake_forward_post(request, upstream_url):
        called["url"] = upstream_url
        return JSONResponse({"alias": True}, status_code=200)

    monkeypatch.setattr(ai_router, "forward_post", fake_forward_post)

    response = client.post("/api/chat", json={"message": "hello"})

    assert response.status_code == 200
    assert response.json() == {"alias": True}
    assert called["url"].endswith("/api/chat")
