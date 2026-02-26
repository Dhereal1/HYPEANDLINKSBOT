const { Bot, webhookCallback } = require('grammy');

const config = require('./config');
const { isAiAvailableCached } = require('./ai-health');
const { HELP_TEXT, FALLBACK_TEXT, startWelcomeText } = require('./text');
const { logError } = require('./logger');

function buildStartMarkup() {
  if (!config.appUrl) return undefined;
  return {
    reply_markup: {
      inline_keyboard: [[{ text: 'Open app', web_app: { url: config.appUrl } }]],
    },
  };
}

function registerHandlers(bot) {
  bot.command('start', async (ctx) => {
    let aiAvailable = false;
    try {
      aiAvailable = await isAiAvailableCached();
    } catch (_) {
      aiAvailable = false;
    }

    const markup = buildStartMarkup();
    await ctx.reply(startWelcomeText(aiAvailable), markup || undefined);
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
}

function getBot() {
  if (globalThis.__vercelGrammyBot) {
    return globalThis.__vercelGrammyBot;
  }

  if (!config.botToken) {
    throw new Error('Missing BOT_TOKEN or TELEGRAM_BOT_TOKEN');
  }

  const bot = new Bot(config.botToken);
  registerHandlers(bot);
  bot.catch((err) => {
    logError('telegram_webhook_error', err.error, {
      update_id: err?.ctx?.update?.update_id || null,
      chat_id: err?.ctx?.chat?.id || null,
      update_kind: err?.ctx?.updateType || 'unknown',
    });
  });

  globalThis.__vercelGrammyBot = bot;
  return bot;
}

function getWebhookHandler() {
  if (globalThis.__vercelGrammyWebhookHandler) {
    return globalThis.__vercelGrammyWebhookHandler;
  }

  const bot = getBot();
  const handler = webhookCallback(bot, 'express', {
    secretToken: config.webhookSecret || undefined,
  });

  globalThis.__vercelGrammyWebhookHandler = handler;
  return handler;
}

module.exports = {
  getBot,
  getWebhookHandler,
};
