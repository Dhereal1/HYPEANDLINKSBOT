# Telegram Bot Service (Vercel, Next.js + grammY)

Standalone webhook bot service for deployment on Vercel.

## Features

- Next.js App Router webhook endpoint: `POST /api/telegram/webhook`
- Header verification with `X-Telegram-Bot-Api-Secret-Token`
- Antifragile `/start` behavior:
  - If `AI_HEALTH_URL` is reachable -> welcome suggests prompt usage
  - If AI is unavailable -> safe welcome without prompt suggestion
- Minimal stable command set: `/start`, `/help`, `/ping`

## Environment Variables

Required:

- `TELEGRAM_BOT_TOKEN`

Recommended:

- `TELEGRAM_WEBHOOK_SECRET`
- `AI_HEALTH_URL` (prefer unified `/health` endpoint)
- `AI_HEALTH_TIMEOUT_MS` (default `1200`, internally capped to `1500` for webhook safety)
- `TELEGRAM_WEBHOOK_URL` (for webhook scripts)

See `.env.example`.

## Local Development

```bash
cd apps/bot
npm install
npm run dev
```

Health checks:

- `GET /api/health`
- `GET /api/telegram/webhook`

## Webhook Setup

After deploy, set env vars and run:

```bash
cd apps/bot
npm run set:webhook
```

To remove webhook:

```bash
npm run delete:webhook
```

## Vercel Deployment

1. Create a separate Vercel project rooted at `apps/bot`.
2. Set environment variables in Vercel Project Settings.
3. Deploy.
4. Run `npm run set:webhook` with production values.

## Portability Note

This service is isolated in `apps/bot` for clean ownership and safer iteration.
If a single-project Vercel setup under `front/api` is preferred, the webhook logic can be ported 1:1 without changing bot behavior, command contract, timeout policy, or security checks.

## Notes

- If `TELEGRAM_WEBHOOK_SECRET` is unset, webhook still works but header verification is skipped.
- `/start` AI probe is bounded by timeout and fails closed (AI unavailable path) to protect webhook reliability.
- AI probe failures never break `/start`; they only switch to safe welcome mode.
