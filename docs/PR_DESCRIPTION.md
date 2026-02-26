## PR Title

`feat(bot): Vercel-only grammY webhook gateway with antifragile /start`

## Summary

This PR implements the Telegram bot webhook in the existing Vercel JS surface (`front/api/bot.js`) using grammY directly.
No second host is required for this mode: `/api/bot` receives Telegram webhook updates and executes grammY `webhookCallback` in the same function.

## Confirmed Direction

- Webhook settlement on JS side (Vercel)
- grammY remains the bot runtime for this deploy mode
- Televerse is a separate future path when running an additional host

## Gateway Contract

- `GET /api/bot`
  - Health/status for gateway wiring.
- `POST /api/bot`
  - Runs grammY webhook handler in-process.
  - Uses Telegram secret token verification (via grammY webhook callback options).
  - Rejects oversized payloads.
  - Rejects invalid JSON/object payloads.

## Core Behavior

- `/start`
  - Uses bounded AI health probe:
    - `AI_HEALTH_TIMEOUT_MS` default `1200`
    - clamped to `200..1500`
    - cached for short TTL (`AI_HEALTH_CACHE_TTL_MS`, default `30000`)
  - AI up => welcome suggests prompts
  - AI down => safe welcome without prompt suggestion
- `/help` and `/ping` handled locally
- Other text => safe fallback to `/help`

## Security and Reliability

- Secret-token verification (`X-Telegram-Bot-Api-Secret-Token`)
- Payload size limit (`TELEGRAM_BODY_LIMIT_BYTES`, default `262144`)
- Structured sanitized logs (`telegram_webhook_error`, `update_id`, `chat_id`, `update_kind`)
- No raw payload logging in error path

## Files Added

- `front/api/bot.js`
- `front/bot-service/config.js`
- `front/bot-service/logger.js`
- `front/bot-service/text.js`
- `front/bot-service/ai-health.js`
- `front/bot-service/grammy.js`
- `front/scripts/set-telegram-webhook.mjs`
- `front/scripts/delete-telegram-webhook.mjs`

## Files Updated

- `front/package.json` (adds `grammy`)
- `front/vercel.json`
- `front/README.md`

## Manual Smoke Checklist

1. Set env vars (`BOT_TOKEN`, `TELEGRAM_WEBHOOK_SECRET`, optional AI vars).
2. Deploy front to Vercel.
3. Run `node front/scripts/set-telegram-webhook.mjs` with `TELEGRAM_WEBHOOK_URL=https://<domain>/api/bot`.
4. Send `/start` with healthy AI endpoint => prompt suggestion appears.
5. Break `AI_HEALTH_URL` => `/start` safe fallback without prompt suggestion.
6. Send wrong secret header => request rejected.
7. Send malformed/oversized request => rejection path works.

## Notes

- This PR follows the existing `front/api/*.js` deployment pattern.
- `apps/bot` prototype is intentionally out of scope.
- Televerse integration is documented as a future optional extension, not part of current runtime path.
