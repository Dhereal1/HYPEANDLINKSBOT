const { webhookCallback } = require('grammy');
const { getBot } = require('../bot-service/grammy-bot');

function json(res, status, body) {
  res.statusCode = status;
  res.setHeader('Content-Type', 'application/json');
  res.end(JSON.stringify(body));
}

module.exports = async function handler(req, res) {
  if (req.method === 'GET') return json(res, 200, { ok: true, service: 'telegram-gateway' });
  if (req.method !== 'POST') return json(res, 405, { ok: false });

  if (!process.env.BOT_TOKEN && !process.env.TELEGRAM_BOT_TOKEN) {
    return json(res, 503, { ok: false, error: 'BOT_TOKEN missing' });
  }

  const bot = getBot();
  const cb = webhookCallback(bot, 'http');
  return cb(req, res);
};
