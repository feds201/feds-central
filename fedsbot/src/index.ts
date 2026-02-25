import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';
import { loadSessions } from './sessions.js';
import { createDiscordBot } from './discord.js';
import { createServer } from './api.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: path.join(__dirname, '..', '.env') });

console.log(`[init] API key loaded: ${!!process.env.ANTHROPIC_API_KEY} (${process.env.ANTHROPIC_API_KEY?.slice(0, 10)}...)`);

const DISCORD_BOT_TOKEN = process.env.DISCORD_BOT_TOKEN;
const ANTHROPIC_API_KEY = process.env.ANTHROPIC_API_KEY;
const GITHUB_WEBHOOK_SECRET = process.env.GITHUB_WEBHOOK_SECRET;
const API_KEY = process.env.API_KEY;
const PORT = process.env.PORT;

if (!DISCORD_BOT_TOKEN || !ANTHROPIC_API_KEY || !PORT || !GITHUB_WEBHOOK_SECRET || !API_KEY) {
  const missing = [
    !DISCORD_BOT_TOKEN && 'DISCORD_BOT_TOKEN',
    !ANTHROPIC_API_KEY && 'ANTHROPIC_API_KEY',
    !PORT && 'PORT',
    !GITHUB_WEBHOOK_SECRET && 'GITHUB_WEBHOOK_SECRET',
    !API_KEY && 'API_KEY',
  ].filter(Boolean);
  console.error(`Missing required environment variables: ${missing.join(', ')}`);
  process.exit(1);
}

// Load persisted session mappings
loadSessions();

// Start Discord bot
console.log('Starting Fedsbot...');
const client = createDiscordBot(DISCORD_BOT_TOKEN);

// Start Express server
const server = createServer(parseInt(PORT, 10), GITHUB_WEBHOOK_SECRET, API_KEY);

// Graceful shutdown
const shutdown = async () => {
  console.log('Shutting down...');
  await client.destroy();
  server.close();
  process.exit(0);
};

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);
