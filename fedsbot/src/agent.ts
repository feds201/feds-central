import {
  SDKSystemMessage,
  unstable_v2_createSession,
  unstable_v2_resumeSession,
} from '@anthropic-ai/claude-agent-sdk';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, '..', '..');

// Clear NODE_OPTIONS so tsx hooks don't leak into the SDK subprocess
delete process.env.NODE_OPTIONS;

// SDK needs SHELL to find a Posix shell for Bash tool
if (!process.env.SHELL) process.env.SHELL = '/bin/sh';

// V2 SDK ignores the cwd option, so chdir to repo root instead
process.chdir(repoRoot);
console.log(`[agent] Working directory set to: ${process.cwd()}`);

const claudeMd = fs.readFileSync(path.join(repoRoot, 'CLAUDE.md'), 'utf8');
const discordPrompt = fs.readFileSync(path.join(__dirname, '..', 'system-prompt-discord.md'), 'utf8');
const chatPrompt = fs.readFileSync(path.join(__dirname, '..', 'system-prompt-chat.md'), 'utf8');

export type UIType = 'discord' | 'chat';

function getInitMessagePrefix(ui: UIType): string {
  const uiPrompt = ui === 'chat' ? chatPrompt : discordPrompt;
  return 'Here is the CLAUDE.md for reference:\n' + claudeMd + '\n\n --- And here is some additional context:\n' + uiPrompt + '\n\n --- And here is the user message:\n';
}

function getSessionOptions() {
  return {
    model: 'claude-sonnet-4-5',
    // `tools` restricts which tools the agent can use
    tools: ['Read', 'Glob', 'Grep', 'WebSearch', 'WebFetch', 'Bash', 'Task'],
    // `allowedTools` auto-approves them so they don't hang waiting for permission
    allowedTools: ['Read', 'Glob', 'Grep', 'WebSearch', 'WebFetch', 'Bash'],
    // Only allow Task for Explore subagents
    // bypassPermissions is broken in V2: https://github.com/anthropics/claude-code/issues/14279
    permissionMode: 'acceptEdits' as const,
    // Do not use `settingSources: ['project']` as it results in systemPrompt being ignored!
    maxTurns: 5,
    canUseTool: async (toolName: string, input: Record<string, unknown>) => {
      if (toolName === 'Task' && input.subagent_type !== 'Explore') {
        return { behavior: 'deny' as const, message: 'Only Explore subagents are allowed' };
      }
      return { behavior: 'allow' as const, updatedInput: input };
    },
  };
}

interface AgentResult {
  sessionId: string;
  responseText: string;
}

export async function createAgentSession(message: string, ui: UIType = 'discord'): Promise<AgentResult> {
  const session = unstable_v2_createSession(getSessionOptions());
  try {
  await session.send(getInitMessagePrefix(ui) + message);

    let responseText = '';
    let sessionId = '';
    for await (const msg of session.stream()) {
      sessionId = msg.session_id ?? sessionId;
      if (msg.type === 'result') {
        // V2 result messages have .result (final text) and .is_error
        const result = msg as any;
        responseText = result.is_error
          ? 'Sorry, I encountered an error processing your question.'
          : (result.result ?? '');
        break;
      }
    }
    return { sessionId, responseText };
  } finally {
    session.close();
  }
}

export async function resumeAgentSession(
  sessionId: string,
  message: string
): Promise<string> {
  const session = unstable_v2_resumeSession(sessionId, getSessionOptions());
  try {
    await session.send(message);
    let responseText = '';
    for await (const msg of session.stream()) {
      if (msg.type === 'result') {
        const result = msg as any;
        responseText = result.is_error
          ? 'Sorry, I encountered an error processing your question.'
          : (result.result ?? '');
        break;
      }
    }
    return responseText;
  } finally {
    session.close();
  }
}

// --- Streaming variants (for web chat SSE) ---

export interface StreamEvent {
  type: 'session' | 'delta' | 'tool' | 'result' | 'done' | 'error';
  sessionId?: string;
  text?: string;
  toolName?: string;
  toolInput?: Record<string, unknown>;
  message?: string;
}

function* yieldAssistantContent(content: any[]): Generator<StreamEvent> {
  for (const block of content) {
    if (block.type === 'text' && block.text) {
      yield { type: 'delta', text: block.text };
    } else if (block.type === 'tool_use') {
      yield { type: 'tool', toolName: block.name, toolInput: block.input };
    }
  }
}

export async function* streamAgentSession(
  message: string,
  ui: UIType = 'chat'
): AsyncGenerator<StreamEvent> {
  console.log(`[agent] Creating session... (API key in env: ${!!process.env.ANTHROPIC_API_KEY})`);
  const opts = getSessionOptions();
  console.log(`[agent] Options: model=${opts.model}, tools=${opts.tools}, permissionMode=${opts.permissionMode}`);
  const session = unstable_v2_createSession(opts);
  try {
    console.log('[agent] Sending message...');
    await session.send(getInitMessagePrefix(ui) + message);
    console.log('[agent] Message sent, streaming response...');
    let sessionId = '';
    let sessionEmitted = false;
    for await (const msg of session.stream()) {
      sessionId = msg.session_id ?? sessionId;

      if (sessionId && !sessionEmitted) {
        yield { type: 'session', sessionId };
        sessionEmitted = true;
      }

      if (msg.type === 'assistant') {
        const content = (msg as any).message?.content;
        if (Array.isArray(content)) {
          yield* yieldAssistantContent(content);
        }
      }

      if (msg.type === 'result') {
        const r = msg as any;
        if (r.is_error) {
          yield { type: 'error', message: 'Agent encountered an error.' };
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
    console.log('[agent] Closing session');
    session.close();
  }
}

export async function* streamResumeAgentSession(
  sessionId: string,
  message: string
): AsyncGenerator<StreamEvent> {
  const session = unstable_v2_resumeSession(sessionId, getSessionOptions());
  try {
    await session.send(message);
    let currentSessionId = sessionId;
    for await (const msg of session.stream()) {
      currentSessionId = msg.session_id ?? currentSessionId;

      if (msg.type === 'assistant') {
        const content = (msg as any).message?.content;
        if (Array.isArray(content)) {
          yield* yieldAssistantContent(content);
        }
      }

      if (msg.type === 'result') {
        const r = msg as any;
        if (r.is_error) {
          yield { type: 'error', message: 'Agent encountered an error.' };
        } else if (r.result) {
          yield { type: 'result', text: r.result };
        }
        yield { type: 'done', sessionId: currentSessionId };
        break;
      }
    }
  } catch (err: any) {
    yield { type: 'error', message: err.message ?? 'Unknown error' };
  } finally {
    session.close();
  }
}
