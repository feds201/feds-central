import {
  Client,
  GatewayIntentBits,
  Partials,
  Message,
  ThreadChannel,
  ChannelType,
} from 'discord.js';
import { streamAgentSession, streamResumeAgentSession, StreamEvent } from './agent.js';
import { getSessionId, setSessionId } from './sessions.js';
import {
  buildEmbed,
  buildCompactEmbed,
  getToolInputSummary,
  splitText,
  type ToolCallState,
  type ProcessingState,
} from './discord-embeds.js';

type Sendable = { send(options: any): Promise<Message> };

const THROTTLE_MS = 2000;

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
      await handleDM(client, message);
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
      await handleFollowUp(client, message, threadId, sessionId);
      return;
    }

    // In a regular channel: only respond to @mentions
    if (!message.mentions.users.has(client.user!.id)) return;

    const question = message.content.replace(/<@!?\d+>/g, '').trim();
    if (!question) {
      await message.reply('Ask me a question!');
      return;
    }

    await handleNewQuestion(client, message, question);
  });

  client.on('error', (error) => {
    console.error('Discord client error:', error);
  });

  client.login(token);
  return client;
}

async function handleNewQuestion(client: Client, message: Message, question: string): Promise<void> {
  console.log(`New question from ${message.author.tag}: "${question.slice(0, 80)}"`);

  const thread = await message.startThread({
    name: question.slice(0, 95) + (question.length > 95 ? '...' : ''),
    autoArchiveDuration: 60,
  });

  try {
    await collapsePreviousEmbed(client, thread);
    const stream = streamAgentSession(question, 'discord');
    const { sessionId } = await processStream(stream, thread);
    if (sessionId) {
      setSessionId(thread.id, sessionId);
    }
  } catch (err) {
    console.error('Error handling question:', err);
    await thread.send('Sorry, something went wrong. Try asking again!');
  }
}

async function handleFollowUp(
  client: Client,
  message: Message,
  threadId: string,
  sessionId: string
): Promise<void> {
  const question = message.content.replace(/<@!?\d+>/g, '').trim();
  if (!question) return;

  console.log(`Follow-up from ${message.author.tag} in thread ${threadId}`);

  try {
    const thread = message.channel as ThreadChannel;
    await collapsePreviousEmbed(client, thread);
    const stream = streamResumeAgentSession(sessionId, question);
    await processStream(stream, thread);
  } catch (err) {
    console.error('Error handling follow-up:', err);
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

async function handleDM(client: Client, message: Message): Promise<void> {
  const question = message.content.trim();
  if (!question) return;

  const startMsgId = await findConversationStartId(message);
  const sessionId = getSessionId(startMsgId);

  try {
    const channel = message.channel as unknown as Sendable;
    await collapsePreviousEmbed(client, channel);

    if (sessionId) {
      console.log(`DM follow-up from ${message.author.tag}, session start: ${startMsgId}`);
      const stream = streamResumeAgentSession(sessionId, question);
      await processStream(stream, channel);
    } else {
      console.log(`New DM conversation from ${message.author.tag}, start: ${startMsgId}`);
      const stream = streamAgentSession(question, 'discord');
      const result = await processStream(stream, channel);
      if (result.sessionId) {
        setSessionId(startMsgId, result.sessionId);
      }
    }
  } catch (err) {
    console.error('Error handling DM:', err);
    await message.reply('Sorry, something went wrong. Try asking again!');
  }
}

// --- Core stream processing ---

interface StreamResult {
  sessionId?: string;
}

async function processStream(
  stream: AsyncGenerator<StreamEvent>,
  channel: Sendable,
): Promise<StreamResult> {
  const state: ProcessingState = {
    status: 'thinking',
    tools: [],
    startedAt: Date.now(),
  };

  // Tool lookup by ID for fast updates
  const toolMap = new Map<string, ToolCallState>();

  // Send the initial embed
  const statusMsg = await channel.send({ embeds: [buildEmbed(state)] });

  // Throttle state
  let lastEditTime = Date.now();
  let pendingTimeout: ReturnType<typeof setTimeout> | null = null;
  let sessionId: string | undefined;

  function scheduleEdit() {
    const now = Date.now();
    const elapsed = now - lastEditTime;

    if (elapsed >= THROTTLE_MS) {
      doEdit();
    } else {
      // Schedule a deferred edit if not already pending
      if (!pendingTimeout) {
        pendingTimeout = setTimeout(() => {
          pendingTimeout = null;
          doEdit();
        }, THROTTLE_MS - elapsed);
      }
    }
  }

  function flushEdit() {
    if (pendingTimeout) {
      clearTimeout(pendingTimeout);
      pendingTimeout = null;
    }
    doEdit();
  }

  function doEdit() {
    lastEditTime = Date.now();
    statusMsg.edit({ embeds: [buildEmbed(state)] }).catch((err: Error) => {
      console.error('Failed to edit status embed:', err.message);
    });
  }

  let responseText = '';

  for await (const event of stream) {
    switch (event.type) {
      case 'session':
        sessionId = event.sessionId;
        break;

      case 'tool': {
        const tool: ToolCallState = {
          toolUseId: event.toolUseId!,
          toolName: event.toolName!,
          inputSummary: getToolInputSummary(event.toolName!, event.toolInput ?? {}),
          startedAt: Date.now(),
          done: false,
        };
        state.tools.push(tool);
        toolMap.set(tool.toolUseId, tool);
        state.status = 'working';
        scheduleEdit();
        break;
      }

      case 'tool_progress': {
        const tool = toolMap.get(event.toolUseId!);
        if (tool) {
          tool.elapsedSeconds = event.elapsedSeconds;
        }
        scheduleEdit();
        break;
      }

      case 'tool_done': {
        const tool = toolMap.get(event.toolUseId!);
        if (tool) {
          tool.done = true;
          // If we never got a tool_progress, compute elapsed from start time
          if (tool.elapsedSeconds === undefined) {
            tool.elapsedSeconds = (Date.now() - tool.startedAt) / 1000;
          }
          if (event.isError && event.text) {
            tool.error = event.text;
          }
        }
        scheduleEdit();
        break;
      }

      case 'delta':
        // Intermediate text — we accumulate it but don't show it in the embed
        // (the final result will be shown as message content)
        break;

      case 'result':
        responseText = event.text ?? '';
        break;

      case 'error':
        state.status = 'error';
        state.errorMessage = event.message ?? 'Unknown error';
        // Mark any in-progress tools as done
        for (const tool of state.tools) {
          if (!tool.done) {
            tool.done = true;
            if (tool.elapsedSeconds === undefined) {
              tool.elapsedSeconds = (Date.now() - tool.startedAt) / 1000;
            }
          }
        }
        flushEdit();
        break;

      case 'done':
        // Mark any remaining in-progress tools as done
        for (const tool of state.tools) {
          if (!tool.done) {
            tool.done = true;
            if (tool.elapsedSeconds === undefined) {
              tool.elapsedSeconds = (Date.now() - tool.startedAt) / 1000;
            }
          }
        }

        if (state.status !== 'error') {
          state.status = 'done';
        }

        // Final edit: add response text as message content, update embed
        flushEdit();
        break;
    }
  }

  // If we errored before 'done', ensure final state
  if (state.status === 'error' && !responseText) {
    // Already handled in the error case above, embed is updated
    // Send error as a fallback text message if no response
    await statusMsg.edit({
      content: null,
      embeds: [buildEmbed(state)],
    });
    return { sessionId };
  }

  // Send the final response
  if (responseText) {
    const chunks = splitText(responseText);
    // First chunk goes into the status message along with the embed
    await statusMsg.edit({
      content: chunks[0],
      embeds: [buildEmbed(state)],
    });
    // Remaining chunks as separate messages
    for (let i = 1; i < chunks.length; i++) {
      await channel.send({ content: chunks[i] });
    }
  } else if (state.status !== 'error') {
    await statusMsg.edit({
      content: "I wasn't able to generate a response. Try rephrasing your question!",
      embeds: [buildEmbed(state)],
    });
  }

  return { sessionId };
}

// --- Collapse previous embed ---

async function collapsePreviousEmbed(client: Client, channel: Sendable): Promise<void> {
  try {
    // Fetch recent messages to find the last bot message with an embed
    const fetchable = channel as unknown as { messages: { fetch(opts: any): Promise<any> } };
    if (!fetchable.messages?.fetch) return;

    const recent = await fetchable.messages.fetch({ limit: 10 });
    const botMsg = recent.find(
      (m: Message) => m.author.id === client.user!.id && m.embeds.length > 0
    );

    if (!botMsg) return;

    // Read the existing embed to determine its state
    const existingEmbed = botMsg.embeds[0];
    if (!existingEmbed?.title) return;

    // Already compact (no description) — nothing to do
    if (!existingEmbed.description) return;

    // Rebuild as compact: keep title and color, drop description
    const compactEmbed = buildCompactEmbed({
      status: existingEmbed.color === 0xFF0000 ? 'error' : 'done',
      tools: [], // Not used by buildCompactEmbed for title — we'll override
      startedAt: 0,
    });
    // Preserve the original title and color
    compactEmbed.setTitle(existingEmbed.title);
    compactEmbed.setColor(existingEmbed.color ?? 0x00CC00);

    await botMsg.edit({ content: botMsg.content || null, embeds: [compactEmbed] });
  } catch (err) {
    // Non-critical — log and continue
    console.error('Failed to collapse previous embed:', err);
  }
}
