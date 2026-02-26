/**
 * grammY bot singleton and dual-mode runners.
 * - Webhook mode: handleWebhook(req, res)
 * - Polling mode: startPolling()
 */
const { Bot, webhookCallback } = require('grammy');
const config = require('./config');
const { isAiAvailableCached } = require('./ai-health');
const { startWelcomeText, HELP_TEXT, FALLBACK_TEXT } = require('./text');
const { makeInlineKeyboardForApp } = require('./telegram');
const { logError, logWarn, logInfo } = require('./logger');

function createBot() {
  if (!config.botToken) {
    throw new Error('BOT_TOKEN (or TELEGRAM_BOT_TOKEN) is required');
  }

  const bot = new Bot(config.botToken);

  bot.command('start', async (ctx) => {
    let aiAvailable = false;
    try {
      aiAvailable = await isAiAvailableCached();
    } catch (_) {
      aiAvailable = false;
    }

    const replyMarkup = makeInlineKeyboardForApp();
    await ctx.reply(startWelcomeText(aiAvailable), {
      reply_markup: replyMarkup || undefined,
    });
  });

  bot.command('help', async (ctx) => {
    await ctx.reply(HELP_TEXT);
  });

  bot.command('ping', async (ctx) => {
    await ctx.reply('pong');
  });

  bot.on('message:text', async (ctx) => {
    await ctx.reply(FALLBACK_TEXT);
  });

  bot.on('message', async (ctx) => {
    if (ctx.message?.text) return;
    logWarn('telegram_update_ignored', {
      update_id: ctx.update?.update_id ?? null,
      reason: 'no_supported_message',
    });
    await ctx.reply(FALLBACK_TEXT).catch(() => {});
  });

  bot.catch((err) => {
    logError('telegram_webhook_error', err, {
      update_id: err.ctx?.update?.update_id ?? null,
      chat_id: err.ctx?.chat?.id ?? null,
      update_kind: err.ctx?.update?.message ? 'message' : 'unknown',
    });
  });

  return bot;
}

function getBot() {
  if (!globalThis.__grammyBotSingleton) {
    globalThis.__grammyBotSingleton = createBot();
  }
  return globalThis.__grammyBotSingleton;
}

function getWebhookHandler() {
  if (!globalThis.__grammyWebhookHandlerSingleton) {
    globalThis.__grammyWebhookHandlerSingleton = webhookCallback(getBot(), 'express', {
      secretToken: config.webhookSecret || undefined,
    });
  }
  return globalThis.__grammyWebhookHandlerSingleton;
}

async function handleWebhook(req, res) {
  const handler = getWebhookHandler();
  return handler(req, res);
}

async function startPolling() {
  const bot = getBot();
  logInfo('bot_polling_start', { mode: 'polling' });
  await bot.start();
}

module.exports = {
  createBot,
  getBot,
  startPolling,
  handleWebhook,
};
