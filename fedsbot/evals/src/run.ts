// Runs every eval case through the bot's real streamAgentSession, inside a sandbox copy without fedsbot/evals.
import crypto from 'crypto';
import fs from 'fs';
import path from 'path';
import { createSandbox, scrubEnv } from './sandbox.js';
import { sessionStats } from './transcript.js';
import { resultsDir } from './paths.js';
import { Case, RunResult, loadCases } from './data.js';

export interface RunOptions {
  name: string;
  reps: number;
  concurrency: number;
  maxUsd: number;
  caseIds?: string[];
  promptDir?: string; // folder with system-prompt-{general,discord,chat}.md (default: the bot's own prompts)
  model?: string;
  effort?: string;
  ref?: string; // run the bot as of this commit instead of your working tree
}

const TRANSIENT = /rate.?limit|overload|\b(429|500|502|503|504|529)\b|timed? ?out|ECONN|ETIMEDOUT|socket|network/i;

/**
 * What the bot actually ran with: settings plus a hash of everything that shapes its answers
 * (agent code, prompts, the repo's CLAUDE.md, and the lockfile, which pins the SDK and so the model behind `sonnet`).
 * Results are only resumed if it matches.
 */
function fingerprint(opts: RunOptions, repoRoot: string, promptDir: string | undefined): Record<string, string | null> {
  const hash = crypto.createHash('sha256');
  const botDir = path.join(repoRoot, 'fedsbot');
  const files = [
    path.join(botDir, 'src', 'agent.ts'), path.join(botDir, 'package-lock.json'), path.join(repoRoot, 'CLAUDE.md'),
    ...['general', 'discord', 'chat'].map(p => path.join(promptDir ?? botDir, `system-prompt-${p}.md`)),
  ];
  for (const file of files) hash.update(path.basename(file)).update(fs.existsSync(file) ? fs.readFileSync(file) : '');
  return { model: opts.model ?? null, effort: opts.effort ?? null, ref: opts.ref ?? null, bot: hash.digest('hex').slice(0, 16) };
}

export async function runCases(opts: RunOptions): Promise<void> {
  const cases = loadCases().filter(c => !opts.caseIds || opts.caseIds.includes(c.id));
  const outDir = resultsDir(opts.name);
  fs.mkdirSync(outDir, { recursive: true });

  const startCwd = process.cwd();
  const sandbox = createSandbox({ ref: opts.ref, promptDir: opts.promptDir });
  const cleanUp = () => { process.chdir(startCwd); sandbox.remove(); };
  // Ctrl-C usually arrives twice (the terminal and tsx both send it), so keep listening while cleaning up.
  let stopping = false;
  const onSignal = () => { if (stopping) return; stopping = true; sandbox.removeInBackground(); process.exit(130); };
  process.on('SIGINT', onSignal);
  process.on('SIGTERM', onSignal);
  let spent = 0;
  try {
    const botDir = path.join(sandbox.root, 'fedsbot');
    const agentSource = fs.readFileSync(path.join(botDir, 'src', 'agent.ts'), 'utf8');
    for (const [flag, env] of [['prompt-dir', 'FEDSBOT_PROMPT_DIR'], ['model', 'FEDSBOT_MODEL'], ['effort', 'FEDSBOT_EFFORT']] as const) {
      const value = flag === 'prompt-dir' ? opts.promptDir : opts[flag];
      if (value && !agentSource.includes(env)) throw new Error(`--${flag} doesn't work with --ref ${opts.ref}: that version of agent.ts doesn't read ${env}`);
    }

    const config = { ...fingerprint(opts, sandbox.root, sandbox.promptDir), promptDir: opts.promptDir ?? null };
    const configFile = path.join(outDir, '_config.json');
    const hasResults = fs.readdirSync(outDir).some(f => /__\d+\.json$/.test(f));
    if (hasResults && fs.existsSync(configFile)) {
      const old = JSON.parse(fs.readFileSync(configFile, 'utf8'));
      const changed = Object.keys(config).filter(k => JSON.stringify(old[k] ?? null) !== JSON.stringify((config as any)[k]));
      if (changed.length) throw new Error(`results/${opts.name} was run with a different bot (${changed.join(', ')} changed). Use a new name, or delete the folder to start over.`);
    }
    fs.writeFileSync(configFile, JSON.stringify({ ...config, updatedAt: new Date().toISOString() }, null, 1));

    scrubEnv();
    // agent.ts reads these at import time
    process.env.ENABLE_CLAUDEAI_MCP_SERVERS = 'false'; // keep the developer's claude.ai connectors out of the bot (prod has none)
    if (sandbox.promptDir) process.env.FEDSBOT_PROMPT_DIR = sandbox.promptDir;
    if (opts.model) process.env.FEDSBOT_MODEL = opts.model;
    if (opts.effort) process.env.FEDSBOT_EFFORT = opts.effort;
    const { streamAgentSession } = await import(path.join(botDir, 'src', 'agent.ts'));

    const jobs = cases.flatMap(c => Array.from({ length: opts.reps }, (_, rep) => ({ c, rep })));
    const runOne = async ({ c, rep }: { c: Case; rep: number }) => {
      const outFile = path.join(outDir, `${c.id}__${rep}.json`);
      if (fs.existsSync(outFile)) return; // reruns resume where they stopped
      if (spent >= opts.maxUsd) return;
      const t0 = Date.now();
      let sessionId = '', answer = '', error: string | undefined, finished = false;
      for await (const ev of streamAgentSession(c.question, 'discord')) {
        if (ev.type === 'session') sessionId = ev.sessionId;
        if (ev.type === 'result') answer = ev.text ?? '';
        if (ev.type === 'error') error = ev.message;
        if (ev.type === 'done') finished = true;
      }
      const latencyMs = Date.now() - t0;
      const stats = sessionId ? sessionStats(sessionId) : undefined;
      spent += stats?.costUsd ?? 0;
      // A session that finished counts, even with no answer (e.g. it hit the turn limit): that's a real failure.
      // A session that died (crash, rate limit, overload, network) isn't saved, so the next run retries it.
      if (!finished || (error && TRANSIENT.test(error))) {
        console.log(`${opts.name} ${c.id}#${rep}: NOT SAVED, ${error ?? 'session did not finish'}; rerun to retry`);
        return;
      }
      const result: RunResult = { case: c.id, rep, question: c.question, answer, error, latencyMs, sessionId, ...stats };
      fs.writeFileSync(outFile, JSON.stringify(result, null, 1));
      const unpriced = stats?.unpricedModels.length ? ` (no price for ${stats.unpricedModels.join(', ')})` : '';
      console.log(`${opts.name} ${c.id}#${rep}: ${(latencyMs / 1000).toFixed(1)}s tools=${stats?.toolCalls ?? '?'} $${(stats?.costUsd ?? 0).toFixed(3)}${unpriced}`);
    };
    const queue = [...jobs];
    await Promise.all(Array.from({ length: opts.concurrency }, async () => { while (queue.length) await runOne(queue.shift()!); }));
  } finally {
    process.off('SIGINT', onSignal);
    process.off('SIGTERM', onSignal);
    cleanUp();
  }
  const missing = cases.length * opts.reps - fs.readdirSync(outDir).filter(f => /__\d+\.json$/.test(f) && cases.some(c => f.startsWith(`${c.id}__`))).length;
  console.log(`${opts.name}: done, about $${spent.toFixed(2)} this run${spent >= opts.maxUsd ? ` (stopped at --max-usd ${opts.maxUsd})` : ''}${missing > 0 ? `; ${missing} runs missing, rerun to finish` : ''}`);
}
