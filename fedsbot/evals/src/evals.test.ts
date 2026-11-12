import { describe, expect, it } from 'vitest';
import { buildBundle } from './bundle.js';
import { controlPasses, parseVerdicts } from './judge.js';
import { summarizeRows, Row, CORRECTION_PENALTY_S } from './summarize.js';
import { Case, Control, RunResult } from './data.js';

const cases: Case[] = [{ id: 'a', split: 'train', type: 'nav', question: 'where is a?' }];
const result = (rep: number): RunResult => ({ case: 'a', rep, question: 'where is a?', answer: `answer ${rep}`, latencyMs: 12345, sessionId: 's', toolCalls: 2 });
const control: Control = { case: 'a', control_id: 'a#7', expect: 'high', answer: 'golden' };

describe('buildBundle', () => {
  it('mixes controls in under opaque ids and keeps a key back to each run', () => {
    const b = buildBundle([result(0), result(1)], [control], cases, 1);
    expect(b.runs).toHaveLength(3);
    expect(new Set(b.runs.map(r => r.run_id)).size).toBe(3);
    for (const r of b.runs) expect(Object.keys(r)).not.toContain('rep');
    const controlKey = b.key.find(k => k.kind === 'control')!;
    expect(b.runs.find(r => r.run_id === controlKey.run_id)!.answer).toBe('golden');
    expect(b.runs.find(r => r.answer === 'answer 1')!.seconds_to_answer).toBe(12.3);
  });

  it('is reproducible for a seed', () => {
    const order = (seed: number) => buildBundle([result(0), result(1), result(2)], [control], cases, seed).runs.map(r => r.answer);
    expect(order(5)).toEqual(order(5));
  });
});

describe('controlPasses', () => {
  const v = (correctness: number, fit: number, outcome: 'satisfied' | 'failed') => ({ run_id: 'r', correctness, fit, outcome, corrections: 0, notes: '' });
  it('needs a high control to score well and a low control to fail or fit <= 2', () => {
    expect(controlPasses('high', v(5, 5, 'satisfied'))).toBe(true);
    expect(controlPasses('high', v(5, 2, 'satisfied'))).toBe(false);
    expect(controlPasses('low', v(1, 1, 'failed'))).toBe(true);
    expect(controlPasses('low fit (pedantic quiz)', v(4, 2, 'satisfied'))).toBe(true);
    expect(controlPasses('low', v(4, 4, 'satisfied'))).toBe(false);
  });
});

describe('parseVerdicts', () => {
  it('reads the JSON array out of the reply', () => {
    expect(parseVerdicts('Here:\n[{"run_id":"r01","correctness":5}]\n')).toEqual([{ run_id: 'r01', correctness: 5 }]);
    expect(() => parseVerdicts('no json')).toThrow();
  });
});

describe('summarizeRows', () => {
  const row = (o: Partial<Row>): Row => ({ case: 'a', split: 'train', correctness: 4, fit: 4, outcome: 'satisfied', corrections: 0, latencyS: 10, costUsd: 0.02, toolCalls: 3, chars: 500, ...o });
  it('leaves failed answers out of latency and adds the penalty per correction', () => {
    const s = summarizeRows([row({}), row({ outcome: 'needs-correction', corrections: 1, latencyS: 10 }), row({ outcome: 'failed', latencyS: 1 })]);
    expect(s.medianLatencyS).toBe(25); // reached: 10 and 10 + 30; the failed run is left out
  });
  it('computes means, rates and the latency median', () => {
    const s = summarizeRows([row({ latencyS: 10 }), row({ latencyS: 20, outcome: 'needs-correction', corrections: 1, correctness: 2 }), row({ outcome: 'failed', fit: 1 })]);
    expect(s.n).toBe(3);
    expect(s.correctness).toBe(3.33);
    expect(s.fit).toBe(3);
    expect(s.firstTryPct).toBe(33);
    expect(s.failedPct).toBe(33);
    expect(s.medianLatencyS).toBe((10 + 20 + CORRECTION_PENALTY_S) / 2);
  });
});
