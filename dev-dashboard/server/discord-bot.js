import { Client, GatewayIntentBits } from 'discord.js';
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: path.join(__dirname, '../.env') });

const GITHUB_OWNER = process.env.GITHUB_OWNER || 'your-github-username';
const GITHUB_REPO = process.env.GITHUB_REPO || 'your-repo-name';
const WORKFLOW_FILE = 'feds-bot-discord.yml';

let client = null;

export const initDiscordBot = () => {
  const token = process.env.DISCORD_BOT_TOKEN;
  const ghToken = process.env.GITHUB_TOKEN;

  if (!token) {
    console.log('⚠️  DISCORD_BOT_TOKEN not set - Discord bot disabled');
    return null;
  }

  if (!ghToken) {
    console.log('⚠️  GITHUB_TOKEN not set - Discord bot disabled');
    return null;
  }

  client = new Client({
    intents: [
      GatewayIntentBits.Guilds,
      GatewayIntentBits.GuildMessages,
      GatewayIntentBits.MessageContent,
    ],
  });

  client.on('ready', () => {
    console.log(`✅ Discord bot logged in as ${client.user.tag}`);
  });

  client.on('messageCreate', async (message) => {
    // Ignore bot messages
    if (message.author.bot) return;

    // Only respond to @mentions of the bot
    if (!message.mentions.has(client.user)) return;

    // Strip the mention from the message to get the question
    const question = message.content.replace(/<@!?\d+>/g, '').trim();

    if (!question) {
      await message.reply('Please include a question after mentioning me!');
      return;
    }

    // Acknowledge receipt
    await message.react('⏳');

    try {
      const response = await fetch(
        `https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/actions/workflows/${WORKFLOW_FILE}/dispatches`,
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${ghToken}`,
            Accept: 'application/vnd.github+json',
            'X-GitHub-Api-Version': '2022-11-28',
          },
          body: JSON.stringify({
            ref: 'main',
            inputs: {
              question,
              channel_id: message.channelId,
              message_id: message.id,
            },
          }),
        }
      );

      if (!response.ok) {
        const body = await response.text();
        console.error(`GitHub API error: ${response.status} ${body}`);
        // Remove hourglass before posting error reply
        await message.reactions.cache.get('⏳')?.users.remove(client.user.id);
        await message.reply('❌ Failed to trigger the workflow. Check server logs.');
      }
      // On success, leave the ⏳ - it will be removed when the workflow posts the actual reply
    } catch (err) {
      console.error('Error dispatching workflow:', err);
      // Remove hourglass before posting error reply
      await message.reactions.cache.get('⏳')?.users.remove(client.user.id);
      await message.reply('❌ Something went wrong triggering the workflow.');
    }
  });

  client.login(token).catch((err) => {
    console.error('Failed to login to Discord:', err);
  });

  return client;
};

export const shutdownDiscordBot = async () => {
  if (client) {
    await client.destroy();
    console.log('Discord bot shut down');
  }
};
