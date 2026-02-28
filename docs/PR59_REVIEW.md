# PR #59 — Feat/dual mode grammy runner — Review

**Branch:** `refs/remotes/pr/59` (open PR)  
**Scope:** Bot: Grammy webhook + local polling from one portable module; Televerse paused; observability.

---

## Summary of changes

| Area | Change |
|------|--------|
| **Dual mode** | Same Grammy bot used for (1) **webhook** on Vercel (`api/bot.js` → `getBot().handleUpdate(update)`) and (2) **local polling** (`run-bot-local.mjs` → `startPolling()`). One `grammy-bot.js`, two entry points. |
| **Portable bot API** | `createBot()` factory, `getBot()` lazy singleton (cached on `globalThis.__hyperlinksGrammyBot`), `startPolling()` for local. Replaces a single top-level `bot` export. |
| **Televerse** | Paused: removed from config (`televerseBaseUrl`, `televerseInternalKey`); `message:text` always replies with `FALLBACK_TEXT` (no forward). `downstream.js` / `router.js` commented as legacy/paused. |
| **Observability** | Dedupe middleware (by `update_id`, 5 min TTL, cleanup at 5k entries); structured logs: `bot_command`, `bot_handler_latency`, `ai_probe_latency`, `telegram_update_duplicate`. |
| **Health** | GET `/api/bot` reports `televerseConfigured: false`. |
| **Docs** | README: fallback text note, “Portability Notes” (webhook vs portable module). |

---

## Is it worth merging?

**Yes.** Reasons:

1. **Aligns with Vercel-only Grammy path** — Single deploy on Vercel, optional local polling; no second runtime (Televerse) in the critical path. Matches the “Vercel-only: Grammy + unified deploy” option in `BOT_VERCEL_MVP_PROPOSAL.md`.
2. **Clean boundary** — `bot-service/grammy-bot.js` is the single portable bot; `api/bot.js` stays a thin webhook (validate → 200 → `getBot().handleUpdate`). Easy to reason about and to move under an `app/` layout later if needed.
3. **Serverless-friendly** — Bot is created lazily via `getBot()` instead of at module load, which plays better with cold starts and multiple invocations.
4. **Dedupe + logging** — Update dedupe and structured logs improve debuggability and guard against duplicate delivery; dedupe is in-memory (per-instance), which is acceptable for serverless (per-invocation).
5. **Explicit pause of Televerse** — Config and forwarding are removed and commented; if you reintroduce a “forward to Dart” path later, you can do it behind a config flag without undoing this refactor.

**Caveats:**

- **Rebase/merge main** — PR may have diverged from `main`; merge or rebase `main` into this branch before merging to avoid conflicts and keep history clean.
- **Televerse later** — Re-enabling Televerse means re-adding config and the `forwardToTeleverse` branch in `message:text` (and possibly a separate entry or env flag). No structural blocker.

---

## Verdict

**Merge (after updating from main).** The PR delivers a single, portable Grammy bot for both webhook (Vercel) and local polling, with Televerse explicitly paused and observability improved. Fits the current “one codebase, Vercel-first” direction.
