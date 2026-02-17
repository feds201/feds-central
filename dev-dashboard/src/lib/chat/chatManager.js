/**
 * Persistent chat service layer.
 *
 * Owns SSE fetch lifecycle independently of React component mounts.
 * Streams are NOT killed when the user switches threads — they keep
 * running and saving to localStorage in the background.
 */

import { getMessages, saveMessages } from './chatStorage'
import { saveThread, getThreads, renameThread } from './chatStorage'

// --- Active streams (threadId → state) ---

const activeStreams = new Map()

// --- Thread-change notifications (for sidebar refresh) ---

const threadChangeListeners = new Set()

function notifyThreadsChanged() {
  threadChangeListeners.forEach((cb) => cb())
}

export function onThreadsChanged(cb) {
  threadChangeListeners.add(cb)
  return () => threadChangeListeners.delete(cb)
}

// --- Public API ---

export function isStreaming(threadId) {
  return activeStreams.has(threadId)
}

export function getStreamState(threadId) {
  const state = activeStreams.get(threadId)
  if (!state) return null
  return { parts: state.parts, status: state.status, error: state.error }
}

export function subscribe(threadId, callback) {
  const state = activeStreams.get(threadId)
  if (!state) return () => {}
  state.listeners.add(callback)
  // Immediate snapshot so the subscriber doesn't miss already-accumulated parts
  if (state.parts.length > 0) {
    callback({ parts: state.parts, status: state.status, error: state.error })
  }
  return () => state.listeners.delete(callback)
}

/**
 * Start a chat stream for `threadId`.
 *
 * - Reads current messages from localStorage
 * - Appends the user message and saves immediately
 * - Starts the SSE fetch (not tied to any component lifecycle)
 * - Saves assistant response to localStorage as it streams (debounced)
 * - Updates thread metadata (agentSessionId, updatedAt, auto-title) on completion
 *
 * No-ops if a stream is already active for this thread.
 */
export function sendMessage(threadId, messageText, { getToken }) {
  if (activeStreams.has(threadId)) return

  // --- Read current state from localStorage (source of truth) ---
  const currentMessages = getMessages(threadId)
  const threads = getThreads()
  const thread = threads.find((t) => t.threadId === threadId)
  let agentSessionId = thread?.agentSessionId || null

  // Persist user message immediately
  const userMessage = { role: 'user', content: [{ type: 'text', text: messageText }] }
  const messagesWithUser = [...currentMessages, userMessage]
  saveMessages(threadId, messagesWithUser)

  // --- Stream state ---
  const state = {
    parts: [],
    status: 'streaming',
    error: null,
    listeners: new Set(),
  }
  activeStreams.set(threadId, state)

  const notify = () => {
    const snapshot = { parts: state.parts, status: state.status, error: state.error }
    state.listeners.forEach((cb) => cb(snapshot))
  }

  const appendText = (text) => {
    const last = state.parts[state.parts.length - 1]
    if (last && last.type === 'text') {
      last.text += text
    } else {
      state.parts.push({ type: 'text', text })
    }
  }

  const saveAssistantMessage = () => {
    const msg = { role: 'assistant', content: state.parts }
    saveMessages(threadId, [...messagesWithUser, msg])
  }

  // --- Fire-and-forget async fetch ---
  ;(async () => {
    try {
      const body = { message: messageText }
      if (agentSessionId) body.sessionId = agentSessionId

      const token = getToken()
      const headers = { 'Content-Type': 'application/json' }
      if (token) headers.Authorization = `Bearer ${token}`

      const res = await fetch('/api/chat', {
        method: 'POST',
        headers,
        body: JSON.stringify(body),
      })

      if (!res.ok) {
        const errText = await res.text()
        appendText(`Error: ${errText}`)
        state.status = 'error'
        state.error = errText
        saveAssistantMessage()
        notify()
        return
      }

      // --- Stream SSE ---
      const reader = res.body.getReader()
      const decoder = new TextDecoder()
      let buffer = ''
      let lastSave = 0

      while (true) {
        const { done, value } = await reader.read()
        if (done) break

        buffer += decoder.decode(value, { stream: true })
        const lines = buffer.split('\n')
        buffer = lines.pop() || ''

        let eventType = null
        for (const line of lines) {
          if (line.startsWith('event: ')) {
            eventType = line.slice(7).trim()
          } else if (line.startsWith('data: ') && eventType) {
            try {
              const data = JSON.parse(line.slice(6))

              if (eventType === 'session' && data.sessionId) {
                agentSessionId = data.sessionId
                saveThread({ threadId, agentSessionId })
              } else if (eventType === 'delta' && data.text) {
                appendText(data.text)
                notify()
                // Debounced localStorage save (every 500ms)
                const now = Date.now()
                if (now - lastSave > 500) {
                  lastSave = now
                  saveAssistantMessage()
                }
              } else if (eventType === 'tool') {
                state.parts.push({
                  type: 'tool-call',
                  toolCallId: crypto.randomUUID(),
                  toolName: data.toolName || 'unknown',
                  args: data.toolInput || {},
                  argsText: JSON.stringify(data.toolInput || {}),
                })
                notify()
              } else if (eventType === 'error') {
                appendText(`\n\n_Error: ${data.message}_`)
                state.status = 'error'
                state.error = data.message
                saveAssistantMessage()
                notify()
                return
              }
            } catch {
              // Ignore malformed JSON lines
            }
            eventType = null
          } else if (line === '') {
            eventType = null
          }
        }
      }

      // --- Stream complete ---
      state.status = 'complete'
      if (state.parts.length === 0) {
        state.parts.push({ type: 'text', text: '(no response)' })
      }
      saveAssistantMessage()

      // Thread metadata
      saveThread({ threadId, updatedAt: new Date().toISOString() })

      // Auto-title from first user message
      const latestThread = getThreads().find((t) => t.threadId === threadId)
      if (latestThread?.title === 'New Chat') {
        renameThread(threadId, messageText.slice(0, 50) + (messageText.length > 50 ? '\u2026' : ''))
      }

      notifyThreadsChanged()
      notify()
    } catch (err) {
      state.status = 'error'
      state.error = err.message
      if (state.parts.length > 0) {
        saveAssistantMessage()
      }
      notifyThreadsChanged()
      notify()
    } finally {
      activeStreams.delete(threadId)
    }
  })()
}
