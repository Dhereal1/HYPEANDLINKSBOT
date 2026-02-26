## PR Title

`feat(bot): add antifragile Telegram webhook service with bounded AI fallback and safe structured logging`

## Summary

This PR adds an isolated Telegram bot service in `apps/bot` using Next.js + grammY.
It is designed as an antifragile webhook entrypoint: secure request validation, bounded AI dependency checks, and safe fallback behavior when AI is unavailable.

## Endpoint Contract

- `GET /api/health`
  - Returns service status and key configuration signals.
- `GET /api/telegram/webhook`
  - Lightweight endpoint status check.
- `POST /api/telegram/webhook`
  - Validates `X-Telegram-Bot-Api-Secret-Token` when configured.
  - Returns `401` on secret mismatch.
  - Returns `400` for malformed JSON.
  - Processes Telegram updates via cached singleton bot instance.

## Reliability And Security Guarantees

- AI health probe timeout is hard-bounded:
  - default `1200ms`
  - clamped to `200..1500ms`
  - invalid/missing values fail closed safely
- `/start` behavior is antifragile:
  - AI reachable => welcome includes prompt suggestion
  - AI unavailable => safe welcome without prompt suggestion
- Structured sanitized error logging in webhook route:
  - event: `telegram_webhook_error`
  - fields: `update_id`, `chat_id`, `update_kind`, `{ name, message }`
  - no raw payload logging
- Webhook security via secret token verification (`401` on mismatch)

## Deployment Model (`apps/bot`) + Portability Note

- Primary deployment target is a separate Vercel project rooted at `apps/bot`.
- This isolation keeps bot-service ownership clean and avoids coupling with existing frontend delivery.
- If team preference is single-project deployment under `front/api`, webhook logic is portable 1:1 with no product/API behavior changes required.

## Manual Smoke Checklist

1. Set env vars and deploy `apps/bot`.
2. Run `npm run set:webhook` with production values.
3. Send `/start` with healthy AI endpoint -> prompt suggestion appears.
4. Set `AI_HEALTH_URL` to invalid target -> `/start` returns safe welcome without prompt suggestion.
5. Send webhook with wrong secret header -> `401`.
6. Send malformed JSON -> `400`.

## Public Interfaces / Contracts (Unchanged)

- `GET /api/health`
- `GET /api/telegram/webhook`
- `POST /api/telegram/webhook`

Environment variables:
- `TELEGRAM_BOT_TOKEN`
- `TELEGRAM_WEBHOOK_SECRET`
- `AI_HEALTH_URL`
- `AI_HEALTH_TIMEOUT_MS` (bounded)
- `TELEGRAM_WEBHOOK_URL`

## Assumptions And Defaults

- Separate Vercel project rooted at `apps/bot`.
- No migration to `front/api` in this PR.
- English copy remains unchanged.
- No DB/stateful idempotency added in this patch.
