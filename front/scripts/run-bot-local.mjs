import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
const { startPolling } = require('../bot-service/grammy-bot');

const token = (process.env.BOT_TOKEN || process.env.TELEGRAM_BOT_TOKEN || '').trim();
if (!token) {
  console.error('Missing BOT_TOKEN or TELEGRAM_BOT_TOKEN');
  process.exit(1);
}

console.warn('[bot:local] Warning: do not run polling with the same token while webhook is active in prod.');
console.warn('[bot:local] Prefer a separate dev bot token or temporarily delete webhook.');

await startPolling();
console.log('[bot:local] Polling started. Press Ctrl+C to stop.');
