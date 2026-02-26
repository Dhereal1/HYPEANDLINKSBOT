/**
 * Vercel serverless: Telegram webhook gateway.
 * Contract: GET = health; POST = validate (size/body) -> grammY webhookCallback.
 */
const config = require('../bot-service/config');
const { handleWebhook } = require('../bot-service/grammy-bot');
const { getChatId, getUpdateKind } = require('../bot-service/telegram');
const { logError, logWarn } = require('../bot-service/logger');

function parseBodySize(req, body, fallbackBytes) {
  const header = Number(req.headers['content-length'] || 0);
  if (Number.isFinite(header) && header > 0) return header;
  try {
    return Buffer.byteLength(JSON.stringify(body || {}), 'utf8');
  } catch (_) {
    return fallbackBytes;
  }
}

module.exports = async (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, X-Telegram-Bot-Api-Secret-Token');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method === 'GET') {
    return res.status(200).json({
      ok: true,
      service: 'telegram-gateway',
      mode: 'webhook',
      framework: 'grammy',
      aiHealthConfigured: Boolean(config.aiHealthUrl),
      televerseConfigured: Boolean(config.televerseBaseUrl && config.televerseInternalKey),
    });
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ ok: false, error: 'method_not_allowed' });
  }

  const bodySize = parseBodySize(req, req.body, config.bodyLimitBytes);
  if (bodySize > config.bodyLimitBytes) {
    return res.status(413).json({ ok: false, error: 'payload_too_large' });
  }

  const update = req.body;
  if (!update || typeof update !== 'object') {
    return res.status(400).json({ ok: false, error: 'invalid_json' });
  }

  try {
    await handleWebhook(req, res);
  } catch (error) {
    logError('telegram_webhook_error', error, {
      update_id: update.update_id || null,
      chat_id: getChatId(update),
      update_kind: getUpdateKind(update),
    });

    if (!res.headersSent) {
      return res.status(200).json({ ok: true });
    }
  }

  if (!config.webhookSecret) {
    logWarn('telegram_webhook_secret_not_set', { update_id: update.update_id || null });
  }
};
