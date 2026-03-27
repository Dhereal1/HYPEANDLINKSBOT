/**
 * Shared Grammy bot.
 * Used by app/bot/webhook (Vercel) and scripts/run-bot-local.ts (polling).
 */
import { Bot, InlineKeyboard, type Context } from 'grammy';
import {
  normalizeUsername,
  upsertUserFromBot,
} from '../database/users.js';
import { handleBotAiResponse } from './responder.js';

function getMiniAppBaseUrl(): string | null {
  const explicit = process.env.MINI_APP_URL?.trim();
  if (explicit) return explicit;
  if (process.env.VERCEL_PROJECT_PRODUCTION_URL) {
    return `https://${process.env.VERCEL_PROJECT_PRODUCTION_URL}`;
  }
  if (process.env.VERCEL_URL) {
    return `https://${process.env.VERCEL_URL}`;
  }
  return null;
}

function buildMiniAppLaunchUrl(baseUrl: string): string | null {
  try {
    const normalized = baseUrl.startsWith('http://') || baseUrl.startsWith('https://')
      ? baseUrl
      : `https://${baseUrl}`;
    const u = new URL(normalized);
    u.searchParams.set('mode', 'fullscreen');
    return u.toString();
  } catch {
    return null;
  }
}

export function createBot(token: string): Bot {
  const bot = new Bot(token);

  async function handleUserUpsert(ctx: Context): Promise<void> {
    try {
      const from = ctx.from;
      if (!from) return;

      const telegramUsername = normalizeUsername(from.username);
      if (!telegramUsername) return;

      const locale =
        typeof from.language_code === 'string' ? from.language_code : null;

      await upsertUserFromBot({ telegramUsername, locale });
    } catch (err) {
      console.error('[bot] upsert user failed', err);
    }
  }

  bot.command('start', async (ctx: Context) => {
    await handleUserUpsert(ctx);
    const message =
      "That's @HyperlinksSpaceBot, you can use AI in bot and explore the app for more features";
    const baseUrl = getMiniAppBaseUrl();
    const launchUrl = baseUrl ? buildMiniAppLaunchUrl(baseUrl) : null;
    if (launchUrl) {
      await ctx.reply(message, {
        reply_markup: new InlineKeyboard().url('Run app', launchUrl),
      });
      return;
    }
    await ctx.reply(message);
  });

  bot.on('message:text', async (ctx: Context) => {
    await handleUserUpsert(ctx);
    await handleBotAiResponse(ctx);
  });

  bot.on('message:caption', async (ctx: Context) => {
    await handleUserUpsert(ctx);
    await handleBotAiResponse(ctx);
  });

  bot.catch((err) => {
    console.error('[bot]', err);
  });

  return bot;
}
