// Combines run stats with judge verdicts into one summary per variant.
import fs from 'fs';
import path from 'path';
import { JudgedRun } from './judge.js';
import { loadCases, loadResults } from './data.js';
import { resultsDir } from './paths.js';

export const CORRECTION_PENALTY_S = 30; // each "no, I meant X" turn costs the student about this long

export interface Row {
  case: string; split: string; correctness: number; fit: number; outcome: string; corrections: number;
  latencyS: number; costUsd: number; toolCalls: number; chars: number;
}
export interface Summary {
  n: number; correctness: number; fit: number; firstTryPct: number; failedPct: number;
  medianLatencyS: number | null; medianToolCalls: number; meanCostUsd: number; medianChars: number;
}

const mean = (xs: number[]) => xs.reduce((a, b) => a + b, 0) / xs.length;
const median = (xs: number[]) => {
  const s = [...xs].sort((a, b) => a - b), m = Math.floor(s.length / 2);
  return s.length % 2 ? s[m] : (s[m - 1] + s[m]) / 2;
};
const r2 = (x: number) => Math.round(x * 100) / 100;

/** Latency counts only answers that got the student there, plus a penalty per correction turn. */
export function summarizeRows(rows: Row[]): Summary {
  const reached = rows.filter(r => r.outcome !== 'failed').map(r => r.latencyS + CORRECTION_PENALTY_S * r.corrections);
  return {
    n: rows.length,
    correctness: r2(mean(rows.map(r => r.correctness))),
    fit: r2(mean(rows.map(r => r.fit))),
    firstTryPct: Math.round(100 * rows.filter(r => r.outcome === 'satisfied').length / rows.length),
    failedPct: Math.round(100 * rows.filter(r => r.outcome === 'failed').length / rows.length),
    medianLatencyS: reached.length ? Math.round(median(reached) * 10) / 10 : null,
    medianToolCalls: median(rows.map(r => r.toolCalls)),
    meanCostUsd: Math.round(mean(rows.map(r => r.costUsd)) * 10000) / 10000,
    medianChars: median(rows.map(r => r.chars)),
  };
}

export function summarize(name: string) {
  const judged: JudgedRun[] = JSON.parse(fs.readFileSync(path.join(resultsDir(name), '_judged.json'), 'utf8'));
  const split = new Map(loadCases().map(c => [c.id, c.split]));
  const verdict = new Map(judged.filter(j => j.key.kind === 'run').map(j => [j.key.kind === 'run' ? `${j.key.case}#${j.key.rep}` : '', j.verdict]));
  const rows: Row[] = loadResults(name).map(r => {
    const v = verdict.get(`${r.case}#${r.rep}`);
    if (!v) throw new Error(`${name}: no verdict for ${r.case}#${r.rep}; run judge again`);
    return {
      case: r.case, split: split.get(r.case) ?? '?', correctness: v.correctness, fit: v.fit, outcome: v.outcome,
      corrections: v.corrections ?? 0, latencyS: r.latencyMs / 1000, costUsd: r.costUsd ?? 0, toolCalls: r.toolCalls ?? 0, chars: r.answer.length,
    };
  });
  const out = {
    all: summarizeRows(rows),
    train: summarizeRows(rows.filter(r => r.split === 'train')),
    holdout: summarizeRows(rows.filter(r => r.split === 'holdout')),
    rows,
  };
  fs.writeFileSync(path.join(resultsDir(name), '_summary.json'), JSON.stringify(out, null, 1));
  return out;
}

export function printTable(names: string[]) {
  const head = ['variant', 'n', 'correct', 'fit', 'holdout c/f', 'first-try', 'failed', 'latency', 'tools', 'cost'];
  const lines = names.map(n => {
    const { all: a, holdout: h } = summarize(n);
    return [n, a.n, a.correctness, a.fit, h.n ? `${h.correctness}/${h.fit}` : '-', `${a.firstTryPct}%`, `${a.failedPct}%`, `${a.medianLatencyS}s`, a.medianToolCalls, `$${a.meanCostUsd}`].map(String);
  });
  const w = head.map((h, i) => Math.max(h.length, ...lines.map(l => l[i].length)));
  for (const l of [head, ...lines]) console.log(l.map((c, i) => c.padEnd(w[i])).join('  '));
}
