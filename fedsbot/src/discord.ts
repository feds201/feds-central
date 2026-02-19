import {
  Client,
  GatewayIntentBits,
  Partials,
  Message,
  ThreadChannel,
  ChannelType,
} from 'discord.js';
import { createAgentSession, resumeAgentSession } from './agent.js';
import { getSessionId, setSessionId } from './sessions.js';

const DISCORD_MESSAGE_LIMIT = 2000;

export function createDiscordBot(token: string): Client {
  const client = new Client({
    // These intents must also be enabled in the Discord Developer Portal > Bot settings
    intents: [
      GatewayIntentBits.Guilds,          // Required base intent for bot to function in servers
      GatewayIntentBits.GuildMessages,    // Receive messages in channels (for @mention triggers)
      GatewayIntentBits.MessageContent,   // Read message text (privileged — must enable in portal)
      GatewayIntentBits.DirectMessages,   // Receive DMs from students
    ],
    partials: [Partials.Channel],         // Required to receive DM events
  });

  client.on('ready', () => {
    console.log(`Discord bot logged in as ${client.user!.tag}`);
  });

  client.on('messageCreate', async (message: Message) => {
    if (message.author.bot) return;

    // DMs: respond to any message, use message history to detect conversation breaks
    if (message.channel.type === ChannelType.DM) {
      await handleDM(message);
      return;
    }

    const isThread =
      message.channel.type === ChannelType.PublicThread ||
      message.channel.type === ChannelType.PrivateThread;

    // In a tracked thread: respond to any message (no @mention needed)
    if (isThread) {
      const threadId = message.channel.id;
      const sessionId = getSessionId(threadId);
      if (!sessionId) return; // Not our thread
      await handleFollowUp(message, threadId, sessionId);
      return;
    }

    // In a regular channel: only respond to @mentions
    if (!message.mentions.users.has(client.user!.id)) return;

    const question = message.content.replace(/<@!?\d+>/g, '').trim();
    if (!question) {
      await message.reply('Ask me a question!');
      return;
    }

    await handleNewQuestion(message, question);
  });

  client.on('error', (error) => {
    console.error('Discord client error:', error);
  });

  client.login(token);
  return client;
}

async function handleNewQuestion(message: Message, question: string): Promise<void> {
  console.log(`New question from ${message.author.tag}: "${question.slice(0, 80)}"`);

  const thread = await message.startThread({
    name: question.slice(0, 95) + (question.length > 95 ? '...' : ''),
    autoArchiveDuration: 60,
  });

  await message.react('\u23F3');

  try {
    await thread.sendTyping();

    const { sessionId, responseText } = await createAgentSession(question);
    setSessionId(thread.id, sessionId);

    await sendSplitMessages(thread, responseText);
    await message.reactions.cache.get('\u23F3')?.users.remove(message.client.user!.id);
    await message.react('\u2705');
  } catch (err) {
    console.error('Error handling question:', err);
    await message.reactions.cache.get('\u23F3')?.users.remove(message.client.user!.id);
    await message.react('\u274C');
    await thread.send('Sorry, something went wrong. Try asking again!');
  }
}

async function handleFollowUp(
  message: Message,
  threadId: string,
  sessionId: string
): Promise<void> {
  const question = message.content.replace(/<@!?\d+>/g, '').trim();
  if (!question) return;

  console.log(`Follow-up from ${message.author.tag} in thread ${threadId}`);
  await message.react('\u23F3');

  try {
    const thread = message.channel as ThreadChannel;
    await thread.sendTyping();

    const responseText = await resumeAgentSession(sessionId, question);

    await sendSplitMessages(thread, responseText);
    await message.reactions.cache.get('\u23F3')?.users.remove(message.client.user!.id);
    await message.react('\u2705');
  } catch (err) {
    console.error('Error handling follow-up:', err);
    await message.reactions.cache.get('\u23F3')?.users.remove(message.client.user!.id);
    await message.react('\u274C');
    await message.reply('Sorry, something went wrong. Try asking again!');
  }
}

const DM_GAP_MS = 30 * 60 * 1000; // 30 minutes

async function findConversationStartId(message: Message): Promise<string> {
  const fetched = await message.channel.messages.fetch({ limit: 100, before: message.id });

  if (fetched.size === 0) {
    return message.id;
  }

  // Build array sorted newest first: current message + fetched history
  const sorted = Array.from(fetched.values()).sort((a, b) => b.createdTimestamp - a.createdTimestamp);
  const messages = [message, ...sorted];

  // Walk newest → oldest, find first gap > 30 min between consecutive messages
  for (let i = 0; i < messages.length - 1; i++) {
    const gap = messages[i].createdTimestamp - messages[i + 1].createdTimestamp;
    if (gap > DM_GAP_MS) {
      return messages[i].id;
    }
  }

  // No gap found — conversation started at the oldest message in our window
  return messages[messages.length - 1].id;
}

async function handleDM(message: Message): Promise<void> {
  const question = message.content.trim();
  if (!question) return;

  const startMsgId = await findConversationStartId(message);
  const sessionId = getSessionId(startMsgId);

  await message.react('\u23F3');

  try {
    const channel = message.channel as { send(content: string): Promise<unknown> };
    if (sessionId) {
      console.log(`DM follow-up from ${message.author.tag}, session start: ${startMsgId}`);
      const responseText = await resumeAgentSession(sessionId, question);
      await sendSplitMessages(channel, responseText);
    } else {
      console.log(`New DM conversation from ${message.author.tag}, start: ${startMsgId}`);
      const { sessionId: newSessionId, responseText } = await createAgentSession(question);
      setSessionId(startMsgId, newSessionId);
      await sendSplitMessages(channel, responseText);
    }
    await message.reactions.cache.get('\u23F3')?.users.remove(message.client.user!.id);
    await message.react('\u2705');
  } catch (err) {
    console.error('Error handling DM:', err);
    await message.reactions.cache.get('\u23F3')?.users.remove(message.client.user!.id);
    await message.react('\u274C');
    await message.reply('Sorry, something went wrong. Try asking again!');
  }
}

async function sendSplitMessages(channel: { send(content: string): Promise<unknown> }, text: string): Promise<void> {
  if (!text) {
    await channel.send("I wasn't able to generate a response. Try rephrasing your question!");
    return;
  }

  if (text.length <= DISCORD_MESSAGE_LIMIT) {
    await channel.send(text);
    return;
  }

  // Split on paragraph breaks, then newlines, then spaces
  const chunks: string[] = [];
  let remaining = text;

  while (remaining.length > 0) {
    if (remaining.length <= DISCORD_MESSAGE_LIMIT) {
      chunks.push(remaining);
      break;
    }

    let splitIndex = remaining.lastIndexOf('\n\n', DISCORD_MESSAGE_LIMIT);
    if (splitIndex === -1 || splitIndex < DISCORD_MESSAGE_LIMIT / 2) {
      splitIndex = remaining.lastIndexOf('\n', DISCORD_MESSAGE_LIMIT);
    }
    if (splitIndex === -1 || splitIndex < DISCORD_MESSAGE_LIMIT / 2) {
      splitIndex = remaining.lastIndexOf(' ', DISCORD_MESSAGE_LIMIT);
    }
    if (splitIndex === -1 || splitIndex < DISCORD_MESSAGE_LIMIT / 2) {
      splitIndex = DISCORD_MESSAGE_LIMIT;
    }

    chunks.push(remaining.slice(0, splitIndex));
    remaining = remaining.slice(splitIndex).trimStart();
  }

  for (const chunk of chunks) {
    await channel.send(chunk);
  }
}
