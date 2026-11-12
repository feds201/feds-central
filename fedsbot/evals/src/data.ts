import fs from 'fs';
import path from 'path';
import { EVALS_DIR, resultsDir } from './paths.js';

export interface Case { id: string; split: 'train' | 'holdout'; type: string; question: string }
export interface Control { case: string; control_id: string; expect: string; answer: string }
export interface RunResult {
  case: string; rep: number; question: string; answer: string; error?: string; latencyMs: number; sessionId: string;
  costUsd?: number; unpricedModels?: string[]; toolCalls?: number; subagents?: number; models?: string[];
}
export interface Verdict {
  run_id: string; correctness: number; fit: number;
  outcome: 'satisfied' | 'needs-correction' | 'failed'; corrections: number; notes: string;
}

const readJson = <T>(file: string): T => JSON.parse(fs.readFileSync(file, 'utf8'));
export const loadCases = () => readJson<Case[]>(path.join(EVALS_DIR, 'cases.json'));
export const loadControls = () => readJson<Control[]>(path.join(EVALS_DIR, 'controls.json'));
export const loadGoldens = () => fs.readFileSync(path.join(EVALS_DIR, 'goldens.json'), 'utf8');
export const loadRubric = () => fs.readFileSync(path.join(EVALS_DIR, 'rubric.md'), 'utf8');

export function loadResults(name: string): RunResult[] {
  const dir = resultsDir(name);
  return fs.readdirSync(dir).filter(f => /__\d+\.json$/.test(f)).sort().map(f => readJson<RunResult>(path.join(dir, f)));
}
