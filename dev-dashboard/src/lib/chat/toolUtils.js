// --- Constants ---

const TOOL_EMOJIS = {
  Glob: '🔍',
  Grep: '🔎',
  Read: '📖',
  WebSearch: '🌐',
  WebFetch: '🌐',
  Bash: '💻',
  Task: '🧠',
}

const INPUT_SUMMARY_MAX_LENGTH = 50

// --- Pure helper functions ---

export function getToolEmoji(toolName) {
  return TOOL_EMOJIS[toolName] ?? '⚙️'
}

export function getToolInputSummary(toolName, toolInput) {
  const keyMap = {
    Glob: 'pattern',
    Read: 'file_path',
    Grep: 'pattern',
    WebSearch: 'query',
    WebFetch: 'url',
    Bash: 'command',
    Task: 'description',
  }

  const key = keyMap[toolName]
  let value = key ? String(toolInput[key] ?? '') : JSON.stringify(toolInput)

  if (!value) return ''

  // For file paths, truncate from the beginning to keep the filename visible
  if ((toolName === 'Read' || toolName === 'Glob') && value.length > INPUT_SUMMARY_MAX_LENGTH) {
    return '...' + value.slice(-(INPUT_SUMMARY_MAX_LENGTH - 3))
  }

  // For everything else, truncate from the end
  if (value.length > INPUT_SUMMARY_MAX_LENGTH) {
    return value.slice(0, INPUT_SUMMARY_MAX_LENGTH - 3) + '...'
  }

  return value
}

export function formatToolLine({ toolName, inputSummary, elapsedSeconds, done, error }) {
  const emoji = getToolEmoji(toolName)
  const time = done ? `[${(elapsedSeconds ?? 0).toFixed(1)}s]` : '...'
  let line = `${emoji} ${toolName} — ${inputSummary}  ${time}`
  if (error) {
    const truncatedError =
      error.length > 50 ? error.slice(0, 47) + '...' : error
    line += `\n    error: ${truncatedError}`
  }
  return line
}

// --- Event handler (mutates parts array) ---

export function handleToolEvent(parts, eventType, eventData) {
  switch (eventType) {
    case 'tool': {
      parts.push({
        type: 'tool-call',
        toolCallId: eventData.toolUseId,
        toolName: eventData.toolName,
        inputSummary: getToolInputSummary(eventData.toolName, eventData.toolInput ?? {}),
        done: false,
      })
      break
    }

    case 'tool_progress': {
      const part = parts.find(
        (p) => p.type === 'tool-call' && p.toolCallId === eventData.toolUseId
      )
      if (part) {
        part.elapsedSeconds = eventData.elapsedSeconds
      }
      break
    }

    case 'tool_done': {
      const part = parts.find(
        (p) => p.type === 'tool-call' && p.toolCallId === eventData.toolUseId
      )
      if (part) {
        part.done = true
        if (eventData.isError && eventData.text) {
          part.error = eventData.text
        }
      }
      break
    }
  }
}
