# PR #55 Review: feat(bot) — Vercel JS webhook gateway with Televerse forwarding skeleton

**PR:** [feat(bot): add Vercel JS webhook gateway with Televerse forwarding skeleton #55](https://github.com/HyperlinksSpace/HyperlinksSpaceBot/pull/55)

**Refactor before merge:** The gateway was refactored to use **Grammy** for all handling (see `front/bot-service/grammy-bot.js`; `front/api/bot.js` calls `bot.handleUpdate(update)`). Same contract and behavior; dependency `grammy` in `front/package.json`. For an updated PR description to paste into the PR, see **`docs/PR55_DESCRIPTION_UPDATE.md`**.

---

## Summary

This PR adds a production-safe Telegram webhook gateway in `front/api/bot.js` and bot logic in `front/bot-service/*`. The gateway handles core commands locally (`/start`, `/help`, `/ping`), applies webhook safety checks, and can optionally forward sanitized updates to a Televerse (Dart) downstream service.

---

## Verdict: Is it worth merging for "Vercel-only logic, webhook + Grammy"?

| Criterion | Result |
|-----------|--------|
| **Vercel-only webhook** | ✅ Yes — single deploy, one host, one webhook URL. |
| **Webhook + Grammy** | ❌ No — the PR uses **custom JS** (router, helpers), not [Grammy](https://grammy.dev). |

So: **Worth merging for a solid Vercel-only webhook.** It does **not** implement the "webhook + Grammy" path from the proposal; it is a custom JS gateway that could be refactored to use Grammy later if desired.

---

## What the PR delivers

- **GET /api/bot** — Health/status for gateway wiring.
- **POST /api/bot** — Webhook receiver with:
  - `X-Telegram-Bot-Api-Secret-Token` verification (when configured).
  - Payload size limit (`TELEGRAM_BODY_LIMIT_BYTES`).
  - Validation and immediate `200 { ok: true }` (antifragile ACK), then best-effort async processing.
- **Commands:** `/start` (with AI health probe + fallback when AI is down), `/help`, `/ping` handled locally.
- **Optional Televerse forwarding** — Reduced envelope to `POST {TELEVERSE_BASE_URL}/internal/process-update` with `X-Internal-Key`.
- **Security & reliability:** Secret token, body limit, structured error logs, no raw payload in error path.

---

## Comparison with proposal

| Aspect | PR #55 | Proposal "Vercel-only: Grammy" |
|--------|--------|---------------------------------|
| Webhook on Vercel | ✅ `front/api/bot.js` | ✅ `front/api/bot/` |
| Framework | Custom JS (router, helpers) | **Grammy** (`webhookCallback(bot, ...)`) |
| Commands | `/start`, `/help`, `/ping` in gateway | Same, implemented via Grammy |
| Forwarding | Optional → Televerse (reduced envelope) | None (in-process only) |
| Safety | Secret token, body limit, 200 ACK, AI fallback | Would be added around Grammy |
| Unified deploy | ✅ One Vercel project | ✅ Same |

---

## Recommendation

1. **If the goal is a Vercel-only webhook that is production-ready:**  
   **Merge.** You get one deploy, one URL, and a clear contract (health, secret token, limits, AI-down fallback). Optional Televerse path stays available without changing the webhook.

2. **If the goal is Vercel-only and bot logic must use Grammy:**  
   - **Option A:** Merge this PR, then **refactor** the handler to use Grammy (`webhookCallback(bot, ...)`) and move command logic into Grammy handlers.  
   - **Option B:** Do not merge; implement the proposal’s "Vercel-only: Grammy + unified deploy" (e.g. the `route.js` + Grammy example in `docs/BOT_VERCEL_MVP_PROPOSAL.md`) instead.

3. **If custom JS is acceptable and Grammy is not required:**  
   **Merge as-is.** Single codebase, same style as existing `front/api/*.js`, no new dependency.

---

## One-line summary

**Worth merging for Vercel-only webhook and production behavior.** It does not implement "webhook + Grammy"; it is a custom JS gateway. To align with the proposal’s Grammy path, merge and refactor to Grammy, or implement the proposal’s Grammy example separately.
