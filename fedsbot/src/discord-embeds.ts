import { EmbedBuilder } from 'discord.js';

// --- Types ---

export interface ToolCallState {
  toolUseId: string;
  toolName: string;
  inputSummary: string;
  startedAt: number;
  elapsedSeconds?: number;
  done: boolean;
  error?: string;
}

export type ProcessingStatus = 'thinking' | 'working' | 'done' | 'error';

export interface ProcessingState {
  status: ProcessingStatus;
  tools: ToolCallState[];
  startedAt: number;
  errorMessage?: string;
}

// --- Constants ---

const TOOL_EMOJIS: Record<string, string> = {
  Glob: '🔍',
  Grep: '🔎',
  Read: '📖',
  WebSearch: '🌐',
  WebFetch: '🌐',
  Bash: '💻',
  Task: '🧠',
};

const EMBED_COLORS = {
  thinking: 0xFFCC00,
  working: 0xFFCC00,
  done: 0x00CC00,
  error: 0xFF0000,
} as const;

const INPUT_SUMMARY_MAX_LENGTH = 50;

// --- Pure helper functions ---

export function getToolEmoji(toolName: string): string {
  return TOOL_EMOJIS[toolName] ?? '⚙️';
}

export function getToolInputSummary(toolName: string, toolInput: Record<string, unknown>): string {
  const keyMap: Record<string, string> = {
    Glob: 'pattern',
    Read: 'file_path',
    Grep: 'pattern',
    WebSearch: 'query',
    WebFetch: 'url',
    Bash: 'command',
    Task: 'description',
  };

  const key = keyMap[toolName];
  let value = key ? String(toolInput[key] ?? '') : JSON.stringify(toolInput);

  if (!value) return '';

  // For file paths, truncate from the beginning to keep the filename visible
  if ((toolName === 'Read' || toolName === 'Glob') && value.length > INPUT_SUMMARY_MAX_LENGTH) {
    return '...' + value.slice(-(INPUT_SUMMARY_MAX_LENGTH - 3));
  }

  // For everything else, truncate from the end
  if (value.length > INPUT_SUMMARY_MAX_LENGTH) {
    return value.slice(0, INPUT_SUMMARY_MAX_LENGTH - 3) + '...';
  }

  return value;
}

export function formatToolLine(tool: ToolCallState): string {
  const emoji = getToolEmoji(tool.toolName);
  const time = tool.done
    ? `[${(tool.elapsedSeconds ?? 0).toFixed(1)}s]`
    : '...';
  let line = `${emoji} ${tool.toolName} — ${tool.inputSummary}  ${time}`;
  if (tool.error) {
    const truncatedError = tool.error.length > 50
      ? tool.error.slice(0, 47) + '...'
      : tool.error;
    line += `\n    error: ${truncatedError}`;
  }
  return line;
}

export function getEmbedColor(status: ProcessingStatus): number {
  return EMBED_COLORS[status];
}

export function getEmbedTitle(state: ProcessingState): string {
  const elapsed = ((Date.now() - state.startedAt) / 1000).toFixed(1);
  const toolCount = state.tools.length;

  switch (state.status) {
    case 'thinking':
      return 'Thinking...';
    case 'working':
      return `Working... · ${elapsed}s`;
    case 'done':
      return `Done · ${toolCount} tool${toolCount !== 1 ? 's' : ''} · ${elapsed}s`;
    case 'error':
      return `Error · ${toolCount} tool${toolCount !== 1 ? 's' : ''} · ${elapsed}s`;
  }
}

export function buildEmbedDescription(state: ProcessingState): string | null {
  const parts: string[] = [];

  // For error state, show the error message first
  if (state.status === 'error' && state.errorMessage) {
    parts.push(state.errorMessage);
  }

  // Tool call list
  if (state.tools.length > 0) {
    const toolLines = state.tools.map(formatToolLine);
    parts.push(toolLines.join('\n'));
  }

  return parts.length > 0 ? parts.join('\n\n') : null;
}

// --- Embed builders ---

export function buildEmbed(state: ProcessingState): EmbedBuilder {
  const embed = new EmbedBuilder()
    .setColor(getEmbedColor(state.status))
    .setTitle(getEmbedTitle(state));

  const description = buildEmbedDescription(state);
  if (description) {
    embed.setDescription(description);
  }

  return embed;
}

export function buildCompactEmbed(state: ProcessingState): EmbedBuilder {
  return new EmbedBuilder()
    .setColor(getEmbedColor(state.status))
    .setTitle(getEmbedTitle(state));
}

// --- Text splitting (extracted from sendSplitMessages) ---

const DISCORD_MESSAGE_LIMIT = 2000;

export function splitText(text: string, limit: number = DISCORD_MESSAGE_LIMIT): string[] {
  if (!text) return [];
  if (text.length <= limit) return [text];

  const chunks: string[] = [];
  let remaining = text;

  while (remaining.length > 0) {
    if (remaining.length <= limit) {
      chunks.push(remaining);
      break;
    }

    let splitIndex = remaining.lastIndexOf('\n\n', limit);
    if (splitIndex === -1 || splitIndex < limit / 2) {
      splitIndex = remaining.lastIndexOf('\n', limit);
    }
    if (splitIndex === -1 || splitIndex < limit / 2) {
      splitIndex = remaining.lastIndexOf(' ', limit);
    }
    if (splitIndex === -1 || splitIndex < limit / 2) {
      splitIndex = limit;
    }

    chunks.push(remaining.slice(0, splitIndex));
    remaining = remaining.slice(splitIndex).trimStart();
  }

  return chunks;
}
