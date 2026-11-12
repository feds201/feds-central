// Cost, tool calls and models for one bot session, read from Claude Code's transcript files
// (~/.claude/projects/<project>/<sessionId>.jsonl, plus <sessionId>/subagents/*.jsonl).
import fs from 'fs';
import os from 'os';
import path from 'path';

// $ per million tokens: [input, output, cache write 5m, cache write 1h, cache read].
// Update when Anthropic changes prices or a new model shows up (unknown models are reported, not priced).
export const PRICES: Record<string, number[]> = {
  'claude-sonnet-5-5': [2, 10, 2.5, 4, 0.1],
  'claude-sonnet-5': [2, 10, 2.5, 4, 0.2],
  'claude-opus-5-5': [4, 20, 5, 8, 0.2],
  'claude-haiku-5-5': [0.1, 0.5, 0.125, 0.2, 0.01],
  'claude-haiku-4-5-20251001': [1, 5, 1.25, 2, 0.1],
};
const WEB_SEARCH_USD = 0.01;

export interface SessionStats {
  costUsd: number;
  unpricedModels: string[];
  toolCalls: number;
  subagents: number;
  models: string[];
}

function transcriptFiles(sessionId: string): string[] {
  const projects = path.join(process.env.CLAUDE_CONFIG_DIR ?? path.join(os.homedir(), '.claude'), 'projects');
  for (const dir of fs.existsSync(projects) ? fs.readdirSync(projects) : []) {
    const main = path.join(projects, dir, `${sessionId}.jsonl`);
    if (!fs.existsSync(main)) continue;
    const subDir = path.join(projects, dir, sessionId, 'subagents');
    const subs = fs.existsSync(subDir) ? fs.readdirSync(subDir).filter(f => f.endsWith('.jsonl')).map(f => path.join(subDir, f)) : [];
    return [main, ...subs];
  }
  return [];
}

export function sessionStats(sessionId: string): SessionStats {
  const files = transcriptFiles(sessionId);
  const seenMsg = new Set<string>();
  const seenTool = new Set<string>();
  const models = new Set<string>();
  const unpriced = new Set<string>();
  let costUsd = 0;
  for (const file of files) {
    for (const line of fs.readFileSync(file, 'utf8').split('\n')) {
      if (!line.trim()) continue;
      const e = JSON.parse(line);
      if (e.type !== 'assistant' || !e.message) continue;
      for (const b of e.message.content ?? []) if (b.type === 'tool_use') seenTool.add(b.id);
      const { id, usage: u, model } = e.message;
      if (!u || !id || seenMsg.has(id)) continue;
      seenMsg.add(id);
      models.add(model);
      const p = PRICES[model];
      if (!p) { unpriced.add(model); continue; }
      const cw1h = u.cache_creation?.ephemeral_1h_input_tokens ?? 0;
      const cw5 = (u.cache_creation_input_tokens ?? 0) - cw1h;
      costUsd += ((u.input_tokens ?? 0) * p[0] + (u.output_tokens ?? 0) * p[1] + cw5 * p[2] + cw1h * p[3]
        + (u.cache_read_input_tokens ?? 0) * p[4]) / 1e6 + (u.server_tool_use?.web_search_requests ?? 0) * WEB_SEARCH_USD;
    }
  }
  return { costUsd, unpricedModels: [...unpriced], toolCalls: seenTool.size, subagents: Math.max(0, files.length - 1), models: [...models] };
}
