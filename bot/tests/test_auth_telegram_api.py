import asyncio
import json

import pytest

pytest.importorskip("telegram")
pytest.importorskip("aiohttp")

from bot import bot as bot_module


class DummyRequest:
    def __init__(self, payload=None, headers=None, path="/auth/telegram"):
        self._payload = payload if payload is not None else {}
        self.headers = headers or {}
        self.path = path
        self.remote = "test"

    async def json(self):
        return self._payload


def _call_auth(payload):
    return asyncio.run(bot_module.auth_telegram(DummyRequest(payload=payload)))


def _json(response):
    return json.loads(response.text)


def test_auth_telegram_success_assigned(monkeypatch):
    monkeypatch.setenv("BOT_TOKEN", "token")

    monkeypatch.setattr(
        bot_module,
        "verify_telegram_webapp_init_data",
        lambda _init_data, _token, max_age_seconds=86400: {
            "user": {"id": 1, "username": "alice", "first_name": "A"}
        },
    )

    async def _claim(_username: str) -> str:
        return "assigned"

    monkeypatch.setattr(bot_module, "claim_wallet_for_username", _claim)

    resp = _call_auth({"initData": "ok"})
    assert resp.status == 200
    body = _json(resp)
    assert body["ok"] is True
    assert body["wallet_status"] == "assigned"
    assert body["newly_assigned"] is True
    assert body["user"]["username"] == "alice"


def test_auth_telegram_invalid_initdata(monkeypatch):
    monkeypatch.setenv("BOT_TOKEN", "token")
    monkeypatch.setattr(bot_module, "verify_telegram_webapp_init_data", lambda *_args, **_kwargs: None)

    resp = _call_auth({"initData": "bad"})
    assert resp.status == 401
    assert _json(resp) == {"ok": False, "error": "invalid_initdata"}


def test_auth_telegram_missing_username(monkeypatch):
    monkeypatch.setenv("BOT_TOKEN", "token")
    monkeypatch.setattr(bot_module, "verify_telegram_webapp_init_data", lambda *_args, **_kwargs: {"user": {"id": 1}})

    resp = _call_auth({"initData": "ok"})
    assert resp.status == 400
    assert _json(resp) == {"ok": False, "error": "username_required"}


def test_auth_telegram_db_unavailable(monkeypatch):
    monkeypatch.setenv("BOT_TOKEN", "token")
    monkeypatch.setattr(
        bot_module,
        "verify_telegram_webapp_init_data",
        lambda *_args, **_kwargs: {"user": {"id": 1, "username": "alice"}},
    )

    async def _claim(_username: str) -> str:
        return "db_unavailable"

    monkeypatch.setattr(bot_module, "claim_wallet_for_username", _claim)

    resp = _call_auth({"initData": "ok"})
    assert resp.status == 503
    assert _json(resp) == {"ok": False, "error": "db_unavailable"}


def test_auth_telegram_missing_initdata(monkeypatch):
    monkeypatch.setenv("BOT_TOKEN", "token")

    resp = _call_auth({})
    assert resp.status == 400
    assert _json(resp) == {"ok": False, "error": "missing_initData"}
