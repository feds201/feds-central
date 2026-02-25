import { useState, useEffect, useMemo, useCallback, useSyncExternalStore } from 'react'
import {
  AssistantRuntimeProvider, useLocalRuntime, useThread,
  ThreadPrimitive, MessagePrimitive, ComposerPrimitive,
} from '@assistant-ui/react'
import { MarkdownTextPrimitive } from '@assistant-ui/react-markdown'
import remarkGfm from 'remark-gfm'
import '@assistant-ui/react-markdown/styles/dot.css'
import { MessageCircle, Plus, Trash2, Pencil, Check, X, Menu } from 'lucide-react'
import { createChatAdapter } from '@/lib/chat/chatAdapter'
import { onThreadsChanged } from '@/lib/chat/chatManager'
import { getThreads, saveThread, deleteThread as removeThread, renameThread, getMessages } from '@/lib/chat/chatStorage'

function MdText() {
  return <MarkdownTextPrimitive remarkPlugins={[remarkGfm]} className="aui-md" />
}

function UserMessage() {
  return (
    <div className="flex justify-end mb-4">
      <div className="max-w-[80%] px-4 py-3 rounded-2xl bg-indigo-600/80 text-white">
        <MessagePrimitive.Parts components={{ Text: MdText }} />
      </div>
    </div>
  )
}

function AssistantMessage() {
  return (
    <div className="flex justify-start mb-4">
      <div className="max-w-[80%] px-4 py-3 rounded-2xl bg-slate-800/80 border border-slate-700/50 text-slate-100">
        <MessagePrimitive.Parts components={{
          Text: MdText,
          tools: { Fallback: ({ toolName }) => (
            <div className="text-xs font-mono text-slate-400 my-1">⚙ {toolName}</div>
          )},
        }} />
      </div>
    </div>
  )
}

function ThreadContent() {
  const isRunning = useThread((s) => s.isRunning)
  return (
    <ThreadPrimitive.Root className="flex flex-col flex-1 min-h-0">
      <ThreadPrimitive.Viewport className="flex-1 overflow-y-auto p-4">
        <ThreadPrimitive.Empty>
          <div className="flex flex-col items-center justify-center h-full text-slate-500">
            <MessageCircle size={48} className="mb-4 opacity-50" />
            <p className="text-lg font-medium">Start a conversation</p>
            <p className="text-sm mt-1">Ask the FEDS bot anything about the robot, code, or FRC.</p>
          </div>
        </ThreadPrimitive.Empty>
        <ThreadPrimitive.Messages components={{ UserMessage, AssistantMessage }} />
        {isRunning && (
          <div className="flex items-center gap-2 px-4 py-2 text-slate-400 text-sm">
            <span className="inline-block h-4 w-4 rounded-full border-2 border-slate-500 border-t-indigo-400 animate-spin" />
            Thinking…
          </div>
        )}
      </ThreadPrimitive.Viewport>
      <div className="border-t border-slate-700/50 p-4">
        <ComposerPrimitive.Root className="flex items-end gap-2">
          <ComposerPrimitive.Input
            placeholder="Type a message..."
            className="flex-1 resize-none rounded-xl bg-slate-800/50 border border-slate-700/50 text-slate-100 placeholder-slate-500 px-4 py-3 focus:outline-none focus:border-indigo-500 focus:ring-2 focus:ring-indigo-500/30 transition-all"
            autoFocus
          />
          <ComposerPrimitive.Send className="px-4 py-3 rounded-xl bg-gradient-to-r from-indigo-600 to-indigo-500 text-white font-semibold hover:from-indigo-700 hover:to-indigo-600 active:scale-95 transition-all shadow-lg shadow-indigo-500/30 disabled:opacity-40 disabled:pointer-events-none">
            Send
          </ComposerPrimitive.Send>
        </ComposerPrimitive.Root>
      </div>
    </ThreadPrimitive.Root>
  )
}

function ActiveThread({ threadId }) {
  const adapter = useMemo(
    () => createChatAdapter({ threadId, getToken: () => localStorage.getItem('token') }),
    [threadId],
  )
  const initialMessages = useMemo(() => {
    const stored = getMessages(threadId)
    return stored.length > 0 ? stored : undefined
  }, [threadId])
  const runtime = useLocalRuntime(adapter, { initialMessages })

  return (
    <AssistantRuntimeProvider runtime={runtime}>
      <ThreadContent />
    </AssistantRuntimeProvider>
  )
}

function SidebarContent({ threads, activeThreadId, onSelect, onCreate, onDelete, onRename, onClose }) {
  const [editingId, setEditingId] = useState(null)
  const [editValue, setEditValue] = useState('')

  const commitRename = (threadId) => {
    if (editValue.trim()) onRename(threadId, editValue.trim())
    setEditingId(null)
  }

  return (
    <>
      <div className="p-3 border-b border-slate-700/50 flex items-center gap-2">
        <button
          onClick={() => { onCreate(); onClose?.() }}
          className="flex-1 flex items-center justify-center gap-2 px-3 py-2 rounded-xl bg-indigo-600/20 border border-indigo-500/30 text-indigo-300 hover:bg-indigo-600/30 transition-colors text-sm font-medium"
        >
          <Plus size={16} /> New Chat
        </button>
        <button onClick={onClose} className="md:hidden p-2 rounded-xl hover:bg-slate-800/50 text-slate-400">
          <X size={20} />
        </button>
      </div>
      <div className="flex-1 overflow-y-auto p-2 space-y-1">
        {threads.map((thread) => (
          <div
            key={thread.threadId}
            className={`group flex items-center gap-1 rounded-lg px-3 py-2 cursor-pointer transition-colors text-sm ${
              thread.threadId === activeThreadId
                ? 'bg-indigo-600/20 text-indigo-200'
                : 'text-slate-400 hover:bg-slate-800/50 hover:text-slate-200'
            }`}
            onClick={() => { onSelect(thread.threadId); onClose?.() }}
          >
            {editingId === thread.threadId ? (
              <>
                <input
                  value={editValue}
                  onChange={(e) => setEditValue(e.target.value)}
                  onKeyDown={(e) => { if (e.key === 'Enter') commitRename(thread.threadId); if (e.key === 'Escape') setEditingId(null) }}
                  onClick={(e) => e.stopPropagation()}
                  className="flex-1 bg-slate-800 border border-slate-600 rounded px-1 py-0.5 text-sm text-slate-100 focus:outline-none"
                  autoFocus
                />
                <button onClick={(e) => { e.stopPropagation(); commitRename(thread.threadId) }}><Check size={14} className="text-emerald-400" /></button>
                <button onClick={(e) => { e.stopPropagation(); setEditingId(null) }}><X size={14} className="text-slate-500" /></button>
              </>
            ) : (
              <>
                <MessageCircle size={14} className="shrink-0" />
                <div className="flex-1 min-w-0">
                  <span className="block truncate">{thread.title}</span>
                  <span className="block text-[10px] text-slate-600 truncate">
                    {new Date(thread.updatedAt || thread.createdAt).toLocaleString([], { month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit' })}
                  </span>
                </div>
                <div className="hidden group-hover:flex items-center gap-0.5">
                  <button onClick={(e) => { e.stopPropagation(); setEditingId(thread.threadId); setEditValue(thread.title) }} className="p-0.5 rounded hover:bg-slate-700/50"><Pencil size={12} /></button>
                  <button onClick={(e) => { e.stopPropagation(); onDelete(thread.threadId) }} className="p-0.5 rounded hover:bg-red-900/30 text-red-400"><Trash2 size={12} /></button>
                </div>
              </>
            )}
          </div>
        ))}
        {threads.length === 0 && <p className="text-xs text-slate-600 text-center mt-4">No conversations yet</p>}
      </div>
    </>
  )
}

const sorted = (list) => [...list].sort((a, b) => new Date(b.updatedAt || b.createdAt) - new Date(a.updatedAt || a.createdAt))

const MD = 768
const subscribeResize = (cb) => { window.addEventListener('resize', cb); return () => window.removeEventListener('resize', cb) }
const getIsDesktop = () => window.innerWidth >= MD

export default function Chat() {
  const isDesktop = useSyncExternalStore(subscribeResize, getIsDesktop)
  const [threads, setThreads] = useState(() => sorted(getThreads()))
  const [activeThreadId, setActiveThreadId] = useState(() => { const t = getThreads(); return t.length > 0 ? t[0].threadId : null })
  const [sidebarOpen, setSidebarOpen] = useState(false)

  useEffect(() => onThreadsChanged(() => setThreads(sorted(getThreads()))), [])

  const createThread = useCallback(() => {
    const threadId = crypto.randomUUID()
    saveThread({ threadId, agentSessionId: null, title: 'New Chat', createdAt: new Date().toISOString() })
    setThreads(sorted(getThreads()))
    setActiveThreadId(threadId)
  }, [])

  const handleDelete = useCallback((threadId) => {
    removeThread(threadId)
    const updated = getThreads()
    setThreads(updated)
    if (activeThreadId === threadId) setActiveThreadId(updated.length > 0 ? updated[0].threadId : null)
  }, [activeThreadId])

  const handleRename = useCallback((threadId, title) => { renameThread(threadId, title); setThreads(sorted(getThreads())) }, [])

  useEffect(() => { if (threads.length === 0) createThread() }, [])

  return (
    <div className="flex h-full min-h-0 rounded-2xl overflow-hidden glass-card">
      {isDesktop ? (
        <aside className="flex flex-col w-60 shrink-0 border-r border-slate-700/50 bg-slate-900/40">
          <SidebarContent
            threads={threads} activeThreadId={activeThreadId}
            onSelect={setActiveThreadId} onCreate={createThread}
            onDelete={handleDelete} onRename={handleRename}
          />
        </aside>
      ) : (
        <div className={`fixed inset-0 z-30 ${sidebarOpen ? '' : 'pointer-events-none'}`}>
          <div className={`absolute inset-0 bg-black/50 transition-opacity ${sidebarOpen ? 'opacity-100' : 'opacity-0'}`} onClick={() => setSidebarOpen(false)} />
          <aside className={`absolute inset-y-0 left-0 w-72 flex flex-col bg-slate-900/95 backdrop-blur-xl border-r border-slate-700/50 transition-transform ${sidebarOpen ? 'translate-x-0' : '-translate-x-full'}`}>
            <SidebarContent
              threads={threads} activeThreadId={activeThreadId}
              onSelect={setActiveThreadId} onCreate={createThread}
              onDelete={handleDelete} onRename={handleRename}
              onClose={() => setSidebarOpen(false)}
            />
          </aside>
        </div>
      )}

      <div className="flex-1 flex flex-col min-w-0 min-h-0">
        {!isDesktop && (
          <div className="flex items-center gap-3 p-3 border-b border-slate-700/50">
            <button onClick={() => setSidebarOpen(true)} className="p-2 rounded-lg text-slate-400 hover:bg-slate-800/50 hover:text-slate-200 transition-colors">
              <Menu size={20} />
            </button>
            <span className="font-semibold text-slate-200 text-sm">Chat</span>
          </div>
        )}
        {activeThreadId ? (
          <ActiveThread key={activeThreadId} threadId={activeThreadId} />
        ) : (
          <div className="flex items-center justify-center h-full text-slate-500">
            <p>Select or create a chat to get started.</p>
          </div>
        )}
      </div>
    </div>
  )
}
