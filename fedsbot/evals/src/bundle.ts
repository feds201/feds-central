// What the judge sees: every run plus the planted control answers, shuffled, under opaque ids,
// so it can't tell which runs are controls or which variant produced them.
import { Case, Control, RunResult } from './data.js';

export interface BundleRun {
  run_id: string; case: string; question: string; answer: string; error?: string;
  seconds_to_answer: number; tool_calls: number; answer_chars: number;
}
export type BundleKey = { run_id: string } & ({ kind: 'run'; case: string; rep: number } | { kind: 'control'; case: string; control_id: string; expect: string });
export interface Bundle { runs: BundleRun[]; key: BundleKey[] }

// Small seeded PRNG so a bundle's order is reproducible.
function mulberry32(seed: number) {
  return () => {
    seed = (seed + 0x6d2b79f5) | 0;
    let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

export function buildBundle(results: RunResult[], controls: Control[], cases: Case[], seed: number): Bundle {
  const question = new Map(cases.map(c => [c.id, c.question]));
  const rand = mulberry32(seed);
  // Controls borrow the timing and tool count of a real run, so they can't be picked out by their metadata.
  const borrow = () => {
    const r = results.length ? results[Math.floor(rand() * results.length)] : undefined;
    // ±15% on the time and ±1 tool call, so a control isn't an exact twin of the run it borrowed from
    const seconds = (r ? r.latencyMs / 1000 : 10) * (0.85 + 0.3 * rand());
    const tools = Math.max(0, (r?.toolCalls ?? 3) + Math.floor(rand() * 3) - 1);
    return { seconds_to_answer: Math.round(seconds * 10) / 10, tool_calls: tools };
  };
  const items: { run: Omit<BundleRun, 'run_id'>; key: Omit<BundleKey, 'run_id'> }[] = [
    ...results.map(r => ({
      run: { case: r.case, question: r.question, answer: r.answer, error: r.error, seconds_to_answer: Math.round(r.latencyMs / 100) / 10, tool_calls: r.toolCalls ?? 0, answer_chars: r.answer.length },
      key: { kind: 'run' as const, case: r.case, rep: r.rep },
    })),
    ...controls.map(c => ({
      run: { case: c.case, question: question.get(c.case) ?? '', answer: c.answer, ...borrow(), answer_chars: c.answer.length },
      key: { kind: 'control' as const, case: c.case, control_id: c.control_id, expect: c.expect },
    })),
  ];
  for (let i = items.length - 1; i > 0; i--) {
    const j = Math.floor(rand() * (i + 1));
    [items[i], items[j]] = [items[j], items[i]];
  }
  const ids = items.map((_, i) => `r${String(i + 1).padStart(2, '0')}`);
  return {
    runs: items.map((it, i) => ({ run_id: ids[i], ...it.run })),
    key: items.map((it, i) => ({ run_id: ids[i], ...it.key }) as BundleKey),
  };
}
