import { describe, it, expect, vi, beforeEach } from 'vitest';
import {
  getToolEmoji,
  getToolInputSummary,
  formatToolLine,
  getEmbedColor,
  getEmbedTitle,
  buildEmbedDescription,
  buildEmbed,
  buildCompactEmbed,
  splitText,
  type ToolCallState,
  type ProcessingState,
} from './discord-embeds.js';

// --- getToolEmoji ---

describe('getToolEmoji', () => {
  it('returns correct emoji for each known tool', () => {
    expect(getToolEmoji('Glob')).toBe('🔍');
    expect(getToolEmoji('Grep')).toBe('🔎');
    expect(getToolEmoji('Read')).toBe('📖');
    expect(getToolEmoji('WebSearch')).toBe('🌐');
    expect(getToolEmoji('WebFetch')).toBe('🌐');
    expect(getToolEmoji('Bash')).toBe('💻');
    expect(getToolEmoji('Task')).toBe('🧠');
  });

  it('returns fallback emoji for unknown tools', () => {
    expect(getToolEmoji('SomeNewTool')).toBe('⚙️');
  });
});

// --- getToolInputSummary ---

describe('getToolInputSummary', () => {
  it('extracts pattern for Glob', () => {
    expect(getToolInputSummary('Glob', { pattern: 'src/**/*.ts' })).toBe('src/**/*.ts');
  });

  it('extracts file_path for Read', () => {
    expect(getToolInputSummary('Read', { file_path: 'src/agent.ts' })).toBe('src/agent.ts');
  });

  it('extracts pattern for Grep', () => {
    expect(getToolInputSummary('Grep', { pattern: 'handleMessage' })).toBe('handleMessage');
  });

  it('extracts query for WebSearch', () => {
    expect(getToolInputSummary('WebSearch', { query: 'FRC swerve drive' })).toBe('FRC swerve drive');
  });

  it('extracts url for WebFetch', () => {
    expect(getToolInputSummary('WebFetch', { url: 'https://example.com' })).toBe('https://example.com');
  });

  it('extracts command for Bash', () => {
    expect(getToolInputSummary('Bash', { command: 'ls -la' })).toBe('ls -la');
  });

  it('extracts description for Task', () => {
    expect(getToolInputSummary('Task', { description: 'Explore codebase' })).toBe('Explore codebase');
  });

  it('truncates long file paths from the beginning', () => {
    const longPath = '/Users/mihai/dev/frc-feds/feds-central/fedsbot/src/some/deep/nested/agent.ts';
    const result = getToolInputSummary('Read', { file_path: longPath });
    expect(result).toHaveLength(50);
    expect(result).toMatch(/^\.\.\..*agent\.ts$/);
  });

  it('truncates long commands from the end', () => {
    const longCommand = 'npm run build && npm run test && npm run lint && npm run deploy --production';
    const result = getToolInputSummary('Bash', { command: longCommand });
    expect(result).toHaveLength(50);
    expect(result).toMatch(/\.\.\.$/);
  });

  it('returns empty string when key is missing', () => {
    expect(getToolInputSummary('Read', {})).toBe('');
  });

  it('falls back to JSON for unknown tools', () => {
    expect(getToolInputSummary('UnknownTool', { foo: 'bar' })).toBe('{"foo":"bar"}');
  });
});

// --- formatToolLine ---

describe('formatToolLine', () => {
  it('formats a completed tool with elapsed time', () => {
    const tool: ToolCallState = {
      toolUseId: 'id1',
      toolName: 'Glob',
      inputSummary: 'src/**/*.ts',
      startedAt: 0,
      elapsedSeconds: 1.2,
      done: true,
    };
    const line = formatToolLine(tool);
    expect(line).toBe('🔍 Glob — src/**/*.ts  [1.2s]');
  });

  it('formats an in-progress tool with ellipsis', () => {
    const tool: ToolCallState = {
      toolUseId: 'id1',
      toolName: 'WebSearch',
      inputSummary: '"FRC swerve"',
      startedAt: 0,
      done: false,
    };
    const line = formatToolLine(tool);
    expect(line).toBe('🌐 WebSearch — "FRC swerve"  ...');
  });

  it('includes error text for failed tools', () => {
    const tool: ToolCallState = {
      toolUseId: 'id1',
      toolName: 'Bash',
      inputSummary: 'npm test',
      startedAt: 0,
      elapsedSeconds: 2.5,
      done: true,
      error: 'Command exited with code 1',
    };
    const line = formatToolLine(tool);
    expect(line).toContain('[2.5s]');
    expect(line).toContain('error: Command exited with code 1');
  });

  it('truncates long error messages to 50 characters', () => {
    const tool: ToolCallState = {
      toolUseId: 'id1',
      toolName: 'Bash',
      inputSummary: 'npm test',
      startedAt: 0,
      elapsedSeconds: 2.5,
      done: true,
      error: 'This is a very long error message that should be truncated because it exceeds fifty characters by a lot',
    };
    const line = formatToolLine(tool);
    const errorPart = line.split('error: ')[1];
    expect(errorPart.length).toBeLessThanOrEqual(50);
    expect(errorPart).toMatch(/\.\.\.$/);
  });

  it('shows 0.0s for done tool with no elapsed time', () => {
    const tool: ToolCallState = {
      toolUseId: 'id1',
      toolName: 'Read',
      inputSummary: 'file.ts',
      startedAt: 0,
      done: true,
    };
    const line = formatToolLine(tool);
    expect(line).toContain('[0.0s]');
  });
});

// --- getEmbedColor ---

describe('getEmbedColor', () => {
  it('returns yellow for thinking', () => {
    expect(getEmbedColor('thinking')).toBe(0xFFCC00);
  });

  it('returns yellow for working', () => {
    expect(getEmbedColor('working')).toBe(0xFFCC00);
  });

  it('returns green for done', () => {
    expect(getEmbedColor('done')).toBe(0x00CC00);
  });

  it('returns red for error', () => {
    expect(getEmbedColor('error')).toBe(0xFF0000);
  });
});

// --- getEmbedTitle ---

describe('getEmbedTitle', () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  it('returns "Thinking..." for thinking state', () => {
    vi.setSystemTime(5000);
    const state: ProcessingState = {
      status: 'thinking',
      tools: [],
      startedAt: 0,
    };
    expect(getEmbedTitle(state)).toBe('Thinking...');
  });

  it('includes elapsed time for working state', () => {
    vi.setSystemTime(4100);
    const state: ProcessingState = {
      status: 'working',
      tools: [makeTool()],
      startedAt: 0,
    };
    expect(getEmbedTitle(state)).toBe('Working... · 4.1s');
  });

  it('includes tool count and time for done state', () => {
    vi.setSystemTime(9100);
    const state: ProcessingState = {
      status: 'done',
      tools: [makeTool(), makeTool(), makeTool()],
      startedAt: 0,
    };
    expect(getEmbedTitle(state)).toBe('Done · 3 tools · 9.1s');
  });

  it('uses singular "tool" for one tool', () => {
    vi.setSystemTime(2000);
    const state: ProcessingState = {
      status: 'done',
      tools: [makeTool()],
      startedAt: 0,
    };
    expect(getEmbedTitle(state)).toBe('Done · 1 tool · 2.0s');
  });

  it('includes tool count and time for error state', () => {
    vi.setSystemTime(5300);
    const state: ProcessingState = {
      status: 'error',
      tools: [makeTool(), makeTool()],
      startedAt: 0,
      errorMessage: 'Something broke',
    };
    expect(getEmbedTitle(state)).toBe('Error · 2 tools · 5.3s');
  });
});

// --- buildEmbedDescription ---

describe('buildEmbedDescription', () => {
  it('returns null for thinking state with no tools', () => {
    const state: ProcessingState = {
      status: 'thinking',
      tools: [],
      startedAt: 0,
    };
    expect(buildEmbedDescription(state)).toBeNull();
  });

  it('returns tool list for working state', () => {
    const state: ProcessingState = {
      status: 'working',
      tools: [
        { toolUseId: '1', toolName: 'Glob', inputSummary: '**/*.ts', startedAt: 0, elapsedSeconds: 1.2, done: true },
        { toolUseId: '2', toolName: 'Read', inputSummary: 'agent.ts', startedAt: 0, done: false },
      ],
      startedAt: 0,
    };
    const desc = buildEmbedDescription(state)!;
    expect(desc).toContain('🔍 Glob');
    expect(desc).toContain('[1.2s]');
    expect(desc).toContain('📖 Read');
    expect(desc).toContain('...');
  });

  it('shows error message before tool list for error state', () => {
    const state: ProcessingState = {
      status: 'error',
      tools: [
        { toolUseId: '1', toolName: 'Glob', inputSummary: '**/*.ts', startedAt: 0, elapsedSeconds: 1.2, done: true },
      ],
      startedAt: 0,
      errorMessage: 'Error from FEDS Bot: status 500',
    };
    const desc = buildEmbedDescription(state)!;
    const errorIndex = desc.indexOf('Error from FEDS Bot');
    const toolIndex = desc.indexOf('🔍 Glob');
    expect(errorIndex).toBeLessThan(toolIndex);
  });

  it('shows only error message when no tools were called', () => {
    const state: ProcessingState = {
      status: 'error',
      tools: [],
      startedAt: 0,
      errorMessage: 'Connection failed',
    };
    const desc = buildEmbedDescription(state)!;
    expect(desc).toBe('Connection failed');
  });
});

// --- buildEmbed ---

describe('buildEmbed', () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  it('builds a yellow embed for thinking state', () => {
    vi.setSystemTime(1000);
    const state: ProcessingState = { status: 'thinking', tools: [], startedAt: 0 };
    const embed = buildEmbed(state);
    const json = embed.toJSON();
    expect(json.color).toBe(0xFFCC00);
    expect(json.title).toBe('Thinking...');
    expect(json.description).toBeUndefined();
  });

  it('builds a green embed with tool list for done state', () => {
    vi.setSystemTime(9100);
    const state: ProcessingState = {
      status: 'done',
      tools: [
        { toolUseId: '1', toolName: 'Glob', inputSummary: '**/*.ts', startedAt: 0, elapsedSeconds: 1.2, done: true },
      ],
      startedAt: 0,
    };
    const embed = buildEmbed(state);
    const json = embed.toJSON();
    expect(json.color).toBe(0x00CC00);
    expect(json.title).toBe('Done · 1 tool · 9.1s');
    expect(json.description).toContain('🔍 Glob');
  });

  it('builds a red embed with error for error state', () => {
    vi.setSystemTime(5000);
    const state: ProcessingState = {
      status: 'error',
      tools: [
        { toolUseId: '1', toolName: 'Bash', inputSummary: 'npm test', startedAt: 0, elapsedSeconds: 2.5, done: true, error: 'Exit code 1' },
      ],
      startedAt: 0,
      errorMessage: 'Agent session failed with status 500',
    };
    const embed = buildEmbed(state);
    const json = embed.toJSON();
    expect(json.color).toBe(0xFF0000);
    expect(json.description).toContain('Agent session failed');
    expect(json.description).toContain('error: Exit code 1');
  });
});

// --- buildCompactEmbed ---

describe('buildCompactEmbed', () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  it('builds embed with title only (no description)', () => {
    vi.setSystemTime(9100);
    const state: ProcessingState = {
      status: 'done',
      tools: [makeTool(), makeTool(), makeTool()],
      startedAt: 0,
    };
    const embed = buildCompactEmbed(state);
    const json = embed.toJSON();
    expect(json.title).toBe('Done · 3 tools · 9.1s');
    expect(json.description).toBeUndefined();
    expect(json.color).toBe(0x00CC00);
  });
});

// --- splitText ---

describe('splitText', () => {
  it('returns empty array for empty text', () => {
    expect(splitText('')).toEqual([]);
  });

  it('returns single chunk for text within limit', () => {
    expect(splitText('Hello world', 100)).toEqual(['Hello world']);
  });

  it('splits on paragraph breaks when possible', () => {
    const text = 'First paragraph.\n\nSecond paragraph.';
    const chunks = splitText(text, 25);
    expect(chunks).toEqual(['First paragraph.', 'Second paragraph.']);
  });

  it('splits on newlines when no paragraph breaks available', () => {
    const text = 'Line one.\nLine two.\nLine three.';
    const chunks = splitText(text, 20);
    expect(chunks[0]).toBe('Line one.\nLine two.');
  });

  it('splits on spaces as last resort', () => {
    const longWord = 'word '.repeat(50);
    const chunks = splitText(longWord.trim(), 20);
    expect(chunks.length).toBeGreaterThan(1);
    for (const chunk of chunks) {
      expect(chunk.length).toBeLessThanOrEqual(20);
    }
  });

  it('hard splits when no break point exists', () => {
    const text = 'a'.repeat(30);
    const chunks = splitText(text, 10);
    expect(chunks.length).toBe(3);
    expect(chunks[0]).toBe('a'.repeat(10));
  });
});

// --- Helpers ---

function makeTool(overrides?: Partial<ToolCallState>): ToolCallState {
  return {
    toolUseId: 'id-' + Math.random().toString(36).slice(2, 6),
    toolName: 'Read',
    inputSummary: 'file.ts',
    startedAt: 0,
    done: true,
    elapsedSeconds: 1.0,
    ...overrides,
  };
}
