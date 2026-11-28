// A throwaway copy of the repo that the bot runs in during evals.
// It's a plain export of the files (no .git, so no history to dig through) without fedsbot/evals,
// so the bot can't find the golden answers or judge notes while it answers.
import { execFileSync, execSync, spawn } from 'child_process';
import fs from 'fs';
import os from 'os';
import path from 'path';
import { REPO_ROOT, FEDSBOT_DIR } from './paths.js';

// Every sandbox lives here, one folder per eval process. A new run deletes folders whose process is gone,
// so an abandoned sandbox (crash, kill -9) is cleaned up by the next run instead of piling up.
const SANDBOXES = path.join(fs.realpathSync(os.tmpdir()), 'fedsbot-eval');

export interface Sandbox {
  root: string; // the repo copy the bot runs in
  promptDir?: string; // copy of --prompt-dir, outside the repo copy
  remove(): void;
  /** For signal handlers: deletes in a detached process, so it finishes even if this process is killed right after. */
  removeInBackground(): void;
}

/**
 * A real copy of node_modules (a symlink would show the bot the real repo's path). Uses copy-on-write clones on macOS
 * and hard links on Linux, which take a second or two instead of copying ~500 MB; falls back to a plain copy.
 */
function copyNodeModules(from: string, to: string) {
  const attempts = process.platform === 'darwin' ? [['-cR'], ['-R']] : [['-al'], ['-R']];
  for (const flags of attempts) {
    try { execFileSync('cp', [...flags, from, to], { stdio: 'ignore' }); return; } catch { fs.rmSync(to, { recursive: true, force: true }); }
  }
  throw new Error('could not copy node_modules into the sandbox');
}

/**
 * The bot's tools inherit this process's environment, and npm puts the real repo's paths in it
 * (npm_package_json, INIT_CWD, node_modules/.bin on PATH). Drop them so the bot can't find its way to fedsbot/evals.
 */
export function scrubEnv() {
  // Also catch paths that reach the repo through a symlinked folder (e.g. PWD=/home/u/code/... -> /mnt/data/code/...)
  const intoRepo = (value: string) => value.includes(REPO_ROOT) || value.split(path.delimiter).some(part => {
    if (!path.isAbsolute(part)) return false;
    try { return fs.realpathSync(part).startsWith(REPO_ROOT); } catch { return false; }
  });
  delete process.env.OLDPWD;
  for (const [k, v] of Object.entries(process.env)) if (k !== 'PATH' && v && intoRepo(v)) delete process.env[k];
  process.env.PATH = (process.env.PATH ?? '').split(path.delimiter).filter(p => !intoRepo(p)).join(path.delimiter);
}

function alive(pid: number): boolean {
  try { process.kill(pid, 0); return true; } catch (e: any) { return e.code === 'EPERM'; }
}

function removeAbandoned() {
  if (!fs.existsSync(SANDBOXES)) return;
  for (const dir of fs.readdirSync(SANDBOXES)) {
    const pid = Number(dir);
    if (!pid || pid === process.pid || !alive(pid)) fs.rmSync(path.join(SANDBOXES, dir), { recursive: true, force: true });
  }
}

/**
 * Default: the files at HEAD, with your working-tree fedsbot/ copied over them, so uncommitted bot changes are tested.
 * With `ref`: the files at that commit, with their own `npm ci` (use this to rerun an older version of the bot).
 */
export function createSandbox(opts: { ref?: string; promptDir?: string } = {}): Sandbox {
  removeAbandoned();
  const base = path.join(SANDBOXES, String(process.pid));
  fs.rmSync(base, { recursive: true, force: true });
  const root = path.join(base, 'repo');
  fs.mkdirSync(root, { recursive: true });
  const remove = () => fs.rmSync(base, { recursive: true, force: true });

  try {
    execFileSync('git', ['rev-parse', '--verify', '--quiet', `${opts.ref ?? 'HEAD'}^{commit}`], { cwd: REPO_ROOT, stdio: 'ignore' });
  } catch {
    remove();
    throw new Error(`--ref ${opts.ref}: not a commit in this repo`);
  }
  try {
    execSync(`git archive --format=tar ${JSON.stringify(opts.ref ?? 'HEAD')} -- . ':(exclude)fedsbot/evals' | tar -x -C ${JSON.stringify(root)}`,
      { cwd: REPO_ROOT, stdio: ['ignore', 'ignore', 'inherit'], shell: '/bin/sh' });
    const botDir = path.join(root, 'fedsbot');
    if (opts.ref) {
      execFileSync('npm', ['ci', '--silent'], { cwd: botDir, stdio: 'inherit' });
    } else {
      const skip = new Set(['evals', 'node_modules', '.env', 'sessions.json']);
      for (const entry of fs.readdirSync(FEDSBOT_DIR)) {
        if (skip.has(entry)) continue;
        fs.cpSync(path.join(FEDSBOT_DIR, entry), path.join(botDir, entry), { recursive: true, force: true, verbatimSymlinks: true });
      }
      copyNodeModules(path.join(FEDSBOT_DIR, 'node_modules'), path.join(botDir, 'node_modules'));
    }
    let promptDir: string | undefined;
    if (opts.promptDir) {
      promptDir = path.join(base, 'prompts');
      fs.cpSync(path.resolve(opts.promptDir), promptDir, { recursive: true });
    }
    if (fs.existsSync(path.join(botDir, 'evals'))) throw new Error('sandbox still contains fedsbot/evals');
    const removeInBackground = () => spawn('rm', ['-rf', base], { detached: true, stdio: 'ignore' }).unref();
    return { root, promptDir, remove, removeInBackground };
  } catch (err) {
    remove();
    throw err;
  }
}
