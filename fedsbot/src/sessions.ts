import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const SESSIONS_FILE = path.join(__dirname, '..', 'sessions.json');

const sessions = new Map<string, string>();

export function loadSessions(): void {
  try {
    if (fs.existsSync(SESSIONS_FILE)) {
      const data = JSON.parse(fs.readFileSync(SESSIONS_FILE, 'utf8'));
      for (const [threadId, sessionId] of Object.entries(data)) {
        sessions.set(threadId, sessionId as string);
      }
      console.log(`Loaded ${sessions.size} session mappings`);
    }
  } catch (err) {
    console.error('Failed to load sessions:', err);
  }
}

export function getSessionId(threadId: string): string | undefined {
  return sessions.get(threadId);
}

export function setSessionId(threadId: string, sessionId: string): void {
  sessions.set(threadId, sessionId);
  saveSessions();
}

function saveSessions(): void {
  try {
    const data = Object.fromEntries(sessions);
    fs.writeFileSync(SESSIONS_FILE, JSON.stringify(data, null, 2));
  } catch (err) {
    console.error('Failed to save sessions:', err);
  }
}
