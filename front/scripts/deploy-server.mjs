const token = (process.env.BOT_TOKEN || process.env.TELEGRAM_BOT_TOKEN || '').trim();
const webhookUrl = (process.env.TELEGRAM_WEBHOOK_URL || '').trim();
const secret = (process.env.TELEGRAM_WEBHOOK_SECRET || '').trim();

if (!token) {
  console.error('Missing BOT_TOKEN or TELEGRAM_BOT_TOKEN');
  process.exit(1);
}

if (!webhookUrl) {
  console.error('Missing TELEGRAM_WEBHOOK_URL');
  process.exit(1);
}

const endpoint = `https://api.telegram.org/bot${token}/setWebhook`;
const payload = { url: webhookUrl, ...(secret ? { secret_token: secret } : {}) };

const response = await fetch(endpoint, {
  method: 'POST',
  headers: { 'content-type': 'application/json' },
  body: JSON.stringify(payload),
});

const data = await response.json();

if (!response.ok || !data.ok) {
  console.error('[bot:deploy] setWebhook failed', data);
  process.exit(1);
}

console.log('[bot:deploy] Webhook set successfully');
console.log('[bot:deploy] URL:', webhookUrl);
if (secret) {
  console.log('[bot:deploy] Secret token: configured');
} else {
  console.log('[bot:deploy] Secret token: not set');
}
