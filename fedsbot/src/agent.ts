import { EffortLevel, Options, query, SDKMessage } from '@anthropic-ai/claude-agent-sdk';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, '..', '..');

// Clear NODE_OPTIONS so tsx hooks don't leak into the SDK subprocess
delete process.env.NODE_OPTIONS;

// Run the agent from the repo root so its tools see the whole monorepo
process.chdir(repoRoot);
console.log(`[agent] Working directory set to: ${process.cwd()}`);

// Optional overrides, used for local experiments (unset in production)
const promptDir = process.env.FEDSBOT_PROMPT_DIR ?? path.join(__dirname, '..');
const modelOverride = process.env.FEDSBOT_MODEL;
const effortOverride = process.env.FEDSBOT_EFFORT as EffortLevel | undefined;

const claudeMd = fs.readFileSync(path.join(repoRoot, 'CLAUDE.md'), 'utf8');
const generalFedsbotPrompt = fs.readFileSync(path.join(promptDir, 'system-prompt-general.md'), 'utf8');
const discordPrompt = fs.readFileSync(path.join(promptDir, 'system-prompt-discord.md'), 'utf8');
const chatPrompt = fs.readFileSync(path.join(promptDir, 'system-prompt-chat.md'), 'utf8');

export type UIType = 'discord' | 'chat';

function getInitMessagePrefix(ui: UIType): string {
  return `## CLAUDE.md:
${claudeMd}

---

## SYSTEM PROMPT:
${generalFedsbotPrompt}

${ui === 'chat' ? chatPrompt : discordPrompt}

---

## USER MESSAGE:
`;
}

function getSessionOptions(resume?: string): Options {
  return {
    // Alias: always the latest Sonnet the installed SDK knows about
    model: modelOverride ?? 'sonnet',
    ...(effortOverride ? { effort: effortOverride } : {}),
    // `tools` restricts which tools the agent can use
    tools: ['Read', 'Glob', 'Grep', 'WebSearch', 'WebFetch', 'Bash', 'Agent'],
    // `allowedTools` auto-approves them so they don't hang waiting for permission
    // (Agent is gated by canUseTool below: Explore subagents only)
    allowedTools: ['Read', 'Glob', 'Grep', 'WebSearch', 'WebFetch', 'Bash'],
    permissionMode: 'acceptEdits',
    // Don't load filesystem settings (user/project/CLAUDE.md); prompts are passed explicitly above
    settingSources: [],
    maxTurns: 15,
    resume,
    canUseTool: async (toolName, input) => {
      if (toolName === 'Agent' && input.subagent_type !== 'Explore') {
        return { behavior: 'deny', message: 'Only Explore subagents are allowed' };
      }
      return { behavior: 'allow', updatedInput: input };
    },
  };
}

function runAgent(prompt: string, resume?: string): AsyncIterable<SDKMessage> {
  return query({ prompt, options: getSessionOptions(resume) });
}

// --- Streaming variants (for web chat SSE) ---

export interface StreamEvent {
  type: 'session' | 'delta' | 'tool' | 'tool_progress' | 'tool_done' | 'result' | 'done' | 'error';
  sessionId?: string;
  text?: string;
  toolName?: string;
  toolUseId?: string;
  toolInput?: Record<string, unknown>;
  message?: string;
  elapsedSeconds?: number;
  isError?: boolean;
}

function* yieldAssistantContent(content: any[]): Generator<StreamEvent> {
  for (const block of content) {
    if (block.type === 'text' && block.text) {
      yield { type: 'delta', text: block.text };
    } else if (block.type === 'tool_use') {
      yield { type: 'tool', toolUseId: block.id, toolName: block.name, toolInput: block.input };
    }
  }
}

function* yieldToolResults(content: any[]): Generator<StreamEvent> {
  for (const block of content) {
    if (block.type === 'tool_result') {
      const errorText = block.is_error
        ? (typeof block.content === 'string' ? block.content : 'Tool error')
        : undefined;
      yield {
        type: 'tool_done',
        toolUseId: block.tool_use_id,
        isError: !!block.is_error,
        text: errorText,
      };
    }
  }
}

function* handleStreamMessage(msg: any): Generator<StreamEvent> {
  if (msg.type === 'assistant') {
    const content = msg.message?.content;
    if (Array.isArray(content)) {
      yield* yieldAssistantContent(content);
    }
  }

  if (msg.type === 'tool_progress') {
    yield {
      type: 'tool_progress',
      toolUseId: msg.tool_use_id,
      toolName: msg.tool_name,
      elapsedSeconds: msg.elapsed_time_seconds,
    };
  }

  if (msg.type === 'user' && msg.isSynthetic) {
    const content = msg.message?.content;
    if (Array.isArray(content)) {
      yield* yieldToolResults(content);
    }
  }
}

export async function* streamAgentSession(
  message: string,
  ui: UIType = 'chat'
): AsyncGenerator<StreamEvent> {
  console.log(`[agent] Creating session... (API key in env: ${!!process.env.ANTHROPIC_API_KEY})`);
  const opts = getSessionOptions();
  console.log(`[agent] Options: model=${opts.model}, effort=${opts.effort ?? 'default'}, tools=${opts.tools}, permissionMode=${opts.permissionMode}`);
  try {
    let sessionId = '';
    let sessionEmitted = false;
    for await (const msg of runAgent(getInitMessagePrefix(ui) + message)) {
      sessionId = (msg as any).session_id ?? sessionId;

      if (sessionId && !sessionEmitted) {
        yield { type: 'session', sessionId };
        sessionEmitted = true;
      }

      yield* handleStreamMessage(msg);

      if ((msg as any).type === 'result') {
        const r = msg as any;
        if (r.is_error) {
          yield { type: 'error', message: r.errors?.join('; ') ?? 'Agent encountered an error.' };
        } else if (r.result) {
          yield { type: 'result', text: r.result };
        }
        yield { type: 'done', sessionId };
        break;
      }
    }
  } catch (err: any) {
    console.error('[agent] Error:', err.message);
    console.error('[agent] Error stack:', err.stack);
    yield { type: 'error', message: err.message ?? 'Unknown error' };
  } finally {
    console.log('[agent] Session finished');
  }
}

export async function* streamResumeAgentSession(
  sessionId: string,
  message: string
): AsyncGenerator<StreamEvent> {
  try {
    let currentSessionId = sessionId;
    for await (const msg of runAgent(message, sessionId)) {
      currentSessionId = (msg as any).session_id ?? currentSessionId;

      yield* handleStreamMessage(msg);

      if ((msg as any).type === 'result') {
        const r = msg as any;
        if (r.is_error) {
          yield { type: 'error', message: r.errors?.join('; ') ?? 'Agent encountered an error.' };
        } else if (r.result) {
          yield { type: 'result', text: r.result };
        }
        yield { type: 'done', sessionId: currentSessionId };
        break;
      }
    }
  } catch (err: any) {
    yield { type: 'error', message: err.message ?? 'Unknown error' };
  }
}
