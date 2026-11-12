import path from 'path';
import { fileURLToPath } from 'url';

export const EVALS_DIR = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
export const FEDSBOT_DIR = path.resolve(EVALS_DIR, '..');
export const REPO_ROOT = path.resolve(FEDSBOT_DIR, '..');
export const RESULTS_DIR = path.join(EVALS_DIR, 'results');

export const resultsDir = (name: string) => path.join(RESULTS_DIR, name);
