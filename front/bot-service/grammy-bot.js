const { Bot } = require('grammy');
const config = require('./config');
const { isAiAvailableCached } = require('./ai-health');
const { forwardToTeleverse } = require('./downstream');
const { logError, logInfo, logWarn } = require('./logger');
const { makeInlineKeyboardForApp } = require('./telegram');
const { FALLBACK_TEXT, HELP_TEXT, startWelcomeText } = require('./text');

const DEDUPE_TTL_MS = 5 * 60 * 1000;

function createDedupeMiddleware() {
  const seen = new Map();

  return async (ctx, next) => {
    const updateId = ctx.update?.update_id;
    if (!Number.isInteger(updateId)) {
      return next();
    }

    const now = Date.now();
    const expiresAt = seen.get(updateId);
    if (expiresAt && expiresAt > now) {
      logWarn('telegram_update_duplicate', { update_id: updateId });
      return;
    }

    seen.set(updateId, now + DEDUPE_TTL_MS);

    // Opportunistic cleanup to keep memory bounded.
    if (seen.size > 5000) {
      for (const [id, expiry] of seen.entries()) {
        if (expiry <= now) seen.delete(id);
      }
    }

    return next();
  };
}

function createBot() {
  if (!config.botToken) {
    throw new Error('BOT_TOKEN (or TELEGRAM_BOT_TOKEN) is required');
  }

  const bot = new Bot(config.botToken);
  bot.use(createDedupeMiddleware());

  bot.command('start', async (ctx) => {
    logInfo('bot_command', {
      command: '/start',
      update_id: ctx.update?.update_id ?? null,
      chat_id: ctx.chat?.id ?? null,
    });

    let aiAvailable = false;
    try {
      aiAvailable = await isAiAvailableCached();
    } catch (error) {
      logWarn('ai_fallback', { reason: 'probe_error' });
      aiAvailable = false;
    }
    const replyMarkup = makeInlineKeyboardForApp();
    await ctx.reply(startWelcomeText(aiAvailable), {
      reply_markup: replyMarkup || undefined,
    });
  });

  bot.command('help', async (ctx) => {
    logInfo('bot_command', {
      command: '/help',
      update_id: ctx.update?.update_id ?? null,
      chat_id: ctx.chat?.id ?? null,
    });
    await ctx.reply(HELP_TEXT);
  });

  bot.command('ping', async (ctx) => {
    logInfo('bot_command', {
      command: '/ping',
      update_id: ctx.update?.update_id ?? null,
      chat_id: ctx.chat?.id ?? null,
    });
    await ctx.reply('pong');
  });

  bot.on('message:text', async (ctx) => {
    const update = ctx.update;
    try {
      const result = await forwardToTeleverse(update);
      if (!result.forwarded) {
        await ctx.reply(FALLBACK_TEXT);
      }
    } catch (error) {
      logError('televerse_forward_error', error, {
        update_id: update?.update_id ?? null,
        chat_id: ctx.chat?.id ?? null,
        message_id: ctx.message?.message_id ?? null,
      });
      await ctx.reply(FALLBACK_TEXT);
    }
  });

  // Non-text messages (photo, sticker, etc.): reply fallback.
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
  if (!globalThis.__hyperlinksGrammyBot) {
    globalThis.__hyperlinksGrammyBot = createBot();
  }
  return globalThis.__hyperlinksGrammyBot;
}

async function startPolling() {
  const bot = getBot();
  await bot.start();
  return bot;
}

module.exports = {
  createBot,
  getBot,
  startPolling,
};
