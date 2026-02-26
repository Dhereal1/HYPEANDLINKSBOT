## PR Title

`chore(unified): scaffold modular unified service with forward-only defaults and test wiring`

## Summary

This PR creates the first real `services/unified` skeleton as a safe, mergeable foundation for incremental architecture work.

- No runtime cutover.
- No behavior migration.
- Existing services remain source of truth via forwarding.

## Why

We need a single-root modular structure ready for growth (auth, ai, rag, wallet, tasks, feed) without introducing deployment risk.

## What Changed

### New unified service scaffold

- Added `services/unified` service package with:
  - `app/main.py` (FastAPI entrypoint)
  - `app/config.py` (env-driven global + per-route modes)
  - `app/health.py` (`/health` payload + route mode visibility)
  - `app/api/routers/` for `auth`, `ai`, `rag`
  - `app/forwarding/` for legacy upstream calls
  - `app/modules/` placeholders for `auth`, `ai`, `rag`, `wallet`, `tasks`, `feed`
  - `app/observability/` and `app/shared/` placeholders

### Forward-only behavior (default)

- `UNIFIED_MODE=forward` by default.
- Added route-level mode vars (`UNIFIED_AUTH_MODE`, `UNIFIED_AI_MODE`, `UNIFIED_RAG_MODE`, etc.) inheriting from `UNIFIED_MODE`.
- Live routes currently forward to legacy services:
  - `POST /auth/telegram` -> bot
  - `POST /ai/chat` and `POST /api/chat` -> ai backend
  - `POST /rag/query` and `POST /query` -> rag backend

### Operational files

- Added `Dockerfile`, `railway.json`, `requirements.txt`, `scripts/run_local.sh`, and updated `README.md`.

### Tests

- Added `services/unified/tests/test_health.py`
- Added `services/unified/tests/test_forwarding.py`
- Added CI workflow `.github/workflows/unified-tests.yml` to run `pytest` for `services/unified`

## Risk / Safety

- Low risk: scaffold-only PR with forward defaults.
- No legacy code moved or deleted.
- No API contract changes on live forwarded endpoints.

## Verification

Local (inside `services/unified`):

```bash
pip install -r requirements.txt
pytest -q
```

CI:

- `Unified Service Tests` workflow runs on push/PR and executes `pytest` for `services/unified`.

## Follow-ups (Not in this PR)

1. Add wallet/tasks/feed routers with forward stubs.
2. Introduce `shadow` mode diff logging.
3. Migrate one bounded context at a time (starting with wallet/auth policy).
