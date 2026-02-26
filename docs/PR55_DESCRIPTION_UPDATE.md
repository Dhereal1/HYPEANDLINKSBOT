# PR #55 — Description update (paste into PR body or as comment)

Use the text below to update the PR description or add a comment after the Grammy refactor (refactor before merge).

---

## Suggested PR description update

**Title:** `feat(bot): add Vercel JS webhook gateway with Grammy + Televerse forwarding skeleton`

**Summary (replace or append):**

This PR adds a production-safe Telegram webhook gateway in `front/api/bot.js` and bot logic in `front/bot-service/*`. **Refactor before merge:** the gateway now uses **[Grammy](https://grammy.dev)** for all command and message handling (`front/bot-service/grammy-bot.js`), while keeping the original contract and behavior.

- **GET /api/bot** — Health/status (includes `framework: 'grammy'`).
- **POST /api/bot** — Verifies `X-Telegram-Bot-Api-Secret-Token`, rejects oversized payloads, validates JSON, responds `200 { ok: true }` immediately (antifragile ACK), then processes the update via **Grammy** (`bot.handleUpdate(update)`).
- **Commands:** `/start` (with bounded AI health probe + fallback when AI is down), `/help`, `/ping` — implemented as Grammy handlers.
- **Other text:** Optionally forwarded to Televerse; otherwise fallback reply. Non-text messages get fallback reply.
- **Security & reliability:** Unchanged (secret token, body limit, structured logs, no raw payload in error path).

**Dependencies:** `grammy` added in `front/package.json` (Node >=18).

**Files added/updated in refactor:**
- `front/package.json` — add `grammy`, Node >=18
- `front/bot-service/grammy-bot.js` — **new** Grammy bot and handlers
- `front/api/bot.js` — use `bot.handleUpdate(update)` after 200 ACK (replaces `processUpdate(update)` from router)
- `front/README.md` — gateway section updated to "Vercel JS + Grammy"

Existing `front/bot-service/router.js` and helpers remain for reference; the webhook path uses Grammy only.

---

## Short comment (if you only add a comment)

**Refactor before merge:** Gateway now uses [Grammy](https://grammy.dev) for handling. Same contract (GET health, POST validate → 200 ACK → process), same behavior (/start with AI health, /help, /ping, optional Televerse forward). New: `front/bot-service/grammy-bot.js`; `front/api/bot.js` calls `bot.handleUpdate(update)` instead of custom router. Dependency: `grammy` in `front/package.json`.
