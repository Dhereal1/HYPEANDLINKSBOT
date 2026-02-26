# Unified Service

This folder contains the unified runtime skeleton for bot + ai + rag.

Current milestone keeps runtime behavior safe:
- Default mode is `forward` for all live routes.
- Legacy services remain source of truth.
- Unified service owns routing, health, and migration controls.

## Endpoints

- `GET /health`
- `GET /ready`
- `POST /auth/telegram` -> forwards to bot `/auth/telegram`
- `POST /ai/chat` -> forwards to ai `/api/chat`
- `POST /api/chat` -> compatibility alias for `/ai/chat`
- `POST /rag/query` -> forwards to rag `/query`
- `POST /query` -> compatibility alias for `/rag/query`

## Route Modes

Each route supports mode flags:
- `forward` (default)
- `local` (reserved)
- `shadow` (reserved)

## Run local

```bash
cd services/unified
python -m pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8090
```

## Environment

- `UNIFIED_MODE` (`forward` by default)
- `UNIFIED_AUTH_MODE` (default inherits `UNIFIED_MODE`)
- `UNIFIED_AI_MODE` (default inherits `UNIFIED_MODE`)
- `UNIFIED_RAG_MODE` (default inherits `UNIFIED_MODE`)
- `UNIFIED_WALLET_MODE` (default inherits `UNIFIED_MODE`)
- `UNIFIED_TASKS_MODE` (default inherits `UNIFIED_MODE`)
- `UNIFIED_FEED_MODE` (default inherits `UNIFIED_MODE`)
- `UNIFIED_FORWARD_TIMEOUT_SECONDS` (`30` by default)
- `UNIFIED_FORWARD_CONNECT_TIMEOUT_SECONDS` (`5` by default)
- `BOT_BASE_URL` (`http://127.0.0.1:8080` by default)
- `AI_BASE_URL` (`http://127.0.0.1:8000` by default)
- `RAG_BASE_URL` (`http://127.0.0.1:8001` by default)
- `INNER_CALLS_KEY` (forwarded to upstream if request has no `X-API-Key`)
