/**
 * ChatModelAdapter for assistant-ui.
 *
 * Thin proxy — delegates the actual fetch to chatManager and subscribes
 * for live updates to yield back to the runtime. When the runtime aborts
 * (e.g. component unmount on thread switch), we stop yielding but do NOT
 * cancel the chatManager stream. It keeps running in the background.
 */

import { sendMessage, subscribe } from './chatManager'

export function createChatAdapter({ threadId, getToken }) {
  return {
    async *run({ messages, abortSignal }) {
      // Extract latest user message text
      const lastUserMsg = [...messages].reverse().find((m) => m.role === 'user')
      if (!lastUserMsg) return

      const messageText =
        typeof lastUserMsg.content === 'string'
          ? lastUserMsg.content
          : lastUserMsg.content
              .filter((p) => p.type === 'text')
              .map((p) => p.text)
              .join('\n')

      // Kick off stream (no-op if already active for this thread)
      sendMessage(threadId, messageText, { getToken })

      // --- Subscribe to chatManager and yield updates via async queue ---
      let done = false
      const queue = []
      let resolver = null

      const unsub = subscribe(threadId, (snapshot) => {
        if (resolver) {
          const r = resolver
          resolver = null
          r(snapshot)
        } else {
          queue.push(snapshot)
        }
      })

      const onAbort = () => {
        done = true
        unsub()
        if (resolver) {
          const r = resolver
          resolver = null
          r(null)
        }
      }
      abortSignal.addEventListener('abort', onAbort)

      try {
        while (!done) {
          const snapshot =
            queue.length > 0
              ? queue.shift()
              : await new Promise((r) => {
                  resolver = r
                })

          if (!snapshot || done) break

          const yieldValue = {
            content: snapshot.parts.length > 0 ? snapshot.parts : [{ type: 'text', text: '' }],
          }

          if (snapshot.status === 'complete') {
            if (snapshot.parts.length === 0) {
              yieldValue.content = [{ type: 'text', text: '(no response)' }]
            }
            yieldValue.status = { type: 'complete', reason: 'stop' }
          } else if (snapshot.status === 'error') {
            yieldValue.status = { type: 'incomplete', reason: 'error', error: snapshot.error }
          }

          yield yieldValue

          if (snapshot.status === 'complete' || snapshot.status === 'error') break
        }
      } finally {
        abortSignal.removeEventListener('abort', onAbort)
        unsub()
      }
    },
  }
}
