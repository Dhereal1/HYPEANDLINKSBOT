# Unified Service

Structured single-root runtime for bot + ai + rag + wallet-facing APIs.

Current milestone keeps runtime behavior safe:
- Default mode is `forward` for all live routes.
- Legacy services remain source of truth.
- Unified service owns routing, health, and migration controls.

## Endpoints

- `GET /health`
- `GET /ready`
- `POST /auth/telegram` (forward)
- `POST /ai/chat` (forward)
- `POST /api/chat` (compat alias of `/ai/chat`)
- `POST /rag/query` (forward)
- `POST /query` (compat alias of `/rag/query`)

## Route Modes

Each route supports mode flags:
- `forward` (default)
- `local` (reserved)
- `shadow` (reserved)

## Environment

- `UNIFIED_MODE` (default `forward`)
- `UNIFIED_AUTH_MODE` (default inherits `UNIFIED_MODE`)
- `UNIFIED_AI_MODE` (default inherits `UNIFIED_MODE`)
- `UNIFIED_RAG_MODE` (default inherits `UNIFIED_MODE`)
- `UNIFIED_WALLET_MODE` (default inherits `UNIFIED_MODE`)
- `UNIFIED_TASKS_MODE` (default inherits `UNIFIED_MODE`)
- `UNIFIED_FEED_MODE` (default inherits `UNIFIED_MODE`)
- `UNIFIED_FORWARD_TIMEOUT_SECONDS` (default `30`)
- `UNIFIED_FORWARD_CONNECT_TIMEOUT_SECONDS` (default `5`)
- `BOT_BASE_URL` (default `http://127.0.0.1:8080`)
- `AI_BASE_URL` (default `http://127.0.0.1:8000`)
- `RAG_BASE_URL` (default `http://127.0.0.1:8001`)
- `INNER_CALLS_KEY` (fallback to `API_KEY` when present)

## Run Local

```bash
cd services/unified
python -m pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8090
```

