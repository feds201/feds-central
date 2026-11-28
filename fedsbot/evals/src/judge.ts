// Scores a variant's runs with an Opus judge, blind to the variant, with planted control answers mixed in.
import { query } from '@anthropic-ai/claude-agent-sdk';
import fs from 'fs';
import path from 'path';
import { buildBundle, BundleKey } from './bundle.js';
import { loadCases, loadControls, loadGoldens, loadResults, loadRubric, Verdict } from './data.js';
import { EVALS_DIR, REPO_ROOT, resultsDir } from './paths.js';

export interface JudgedRun { key: BundleKey; verdict: Verdict }

/** A control passes when a "high" answer scores >= 4 on both and a "low" one fails or gets fit <= 2. */
export function controlPasses(expect: string, v: Verdict): boolean {
  return expect.startsWith('high') ? v.correctness >= 4 && v.fit >= 4 : v.outcome === 'failed' || v.fit <= 2;
}

export function parseVerdicts(text: string): Verdict[] {
  const start = text.indexOf('['), end = text.lastIndexOf(']');
  if (start < 0 || end < start) throw new Error('judge reply has no JSON array');
  return JSON.parse(text.slice(start, end + 1));
}

export async function judge(name: string, judgeModel = 'opus'): Promise<JudgedRun[]> {
  const results = loadResults(name);
  const bundle = buildBundle(results, loadControls(), loadCases(), name.length * 7919);
  const prompt = fs.readFileSync(path.join(EVALS_DIR, 'judge-prompt.md'), 'utf8')
    .replace('{{RUBRIC}}', loadRubric())
    .replace('{{GOLDENS}}', loadGoldens())
    .replace('{{RUNS}}', JSON.stringify(bundle.runs, null, 1));

  process.env.ENABLE_CLAUDEAI_MCP_SERVERS = 'false';
  let text = '', cost = 0;
  for await (const m of query({
    prompt,
    options: {
      model: judgeModel, cwd: REPO_ROOT, settingSources: [], maxTurns: 60,
      tools: ['Read', 'Grep', 'Glob'], allowedTools: ['Read', 'Grep', 'Glob'],
    },
  })) {
    if (m.type === 'result') {
      cost = m.total_cost_usd;
      if (m.subtype !== 'success') throw new Error(`judge failed: ${m.subtype}`);
      text = m.result;
    }
  }

  const verdicts = new Map(parseVerdicts(text).map(v => [v.run_id, v]));
  const judged = bundle.key.map(key => {
    const verdict = verdicts.get(key.run_id);
    if (!verdict) throw new Error(`judge skipped ${key.run_id}`);
    return { key, verdict };
  });
  fs.writeFileSync(path.join(resultsDir(name), '_judged.json'), JSON.stringify(judged, null, 1));

  const controls = judged.filter(j => j.key.kind === 'control');
  const bad = controls.filter(j => j.key.kind === 'control' && !controlPasses(j.key.expect, j.verdict));
  console.log(`${name}: judged ${judged.length} (judge cost $${cost.toFixed(2)}); controls ${controls.length - bad.length}/${controls.length} as expected`);
  for (const b of bad) if (b.key.kind === 'control') console.log(`  WARNING control ${b.key.control_id} (expected ${b.key.expect}) got ${b.verdict.correctness}/${b.verdict.fit} ${b.verdict.outcome}: rejudge before trusting these scores`);
  return judged;
}
