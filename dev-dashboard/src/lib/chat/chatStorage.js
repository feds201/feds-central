const THREADS_KEY = 'feds-chat-threads';
const MESSAGES_KEY_PREFIX = 'feds-chat-messages-';

// --- Threads ---

export function getThreads() {
  try {
    return JSON.parse(localStorage.getItem(THREADS_KEY) || '[]');
  } catch {
    return [];
  }
}

export function saveThread(thread) {
  const threads = getThreads();
  const idx = threads.findIndex((t) => t.threadId === thread.threadId);
  if (idx >= 0) {
    threads[idx] = { ...threads[idx], ...thread };
  } else {
    threads.unshift(thread);
  }
  localStorage.setItem(THREADS_KEY, JSON.stringify(threads));
}

export function deleteThread(threadId) {
  const threads = getThreads().filter((t) => t.threadId !== threadId);
  localStorage.setItem(THREADS_KEY, JSON.stringify(threads));
  localStorage.removeItem(MESSAGES_KEY_PREFIX + threadId);
}

export function renameThread(threadId, title) {
  const threads = getThreads();
  const thread = threads.find((t) => t.threadId === threadId);
  if (thread) {
    thread.title = title;
    localStorage.setItem(THREADS_KEY, JSON.stringify(threads));
  }
}

// --- Messages ---

export function getMessages(threadId) {
  try {
    return JSON.parse(localStorage.getItem(MESSAGES_KEY_PREFIX + threadId) || '[]');
  } catch {
    return [];
  }
}

export function saveMessages(threadId, messages) {
  localStorage.setItem(MESSAGES_KEY_PREFIX + threadId, JSON.stringify(messages));
}
