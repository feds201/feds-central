import { describe, it, expect } from 'vitest'
import {
  getToolEmoji,
  getToolInputSummary,
  formatToolLine,
  handleToolEvent,
} from './toolUtils'

// --- getToolEmoji ---

describe('getToolEmoji', () => {
  it('returns correct emoji for each known tool', () => {
    expect(getToolEmoji('Glob')).toBe('🔍')
    expect(getToolEmoji('Grep')).toBe('🔎')
    expect(getToolEmoji('Read')).toBe('📖')
    expect(getToolEmoji('WebSearch')).toBe('🌐')
    expect(getToolEmoji('WebFetch')).toBe('🌐')
    expect(getToolEmoji('Bash')).toBe('💻')
    expect(getToolEmoji('Task')).toBe('🧠')
  })

  it('returns fallback emoji for unknown tools', () => {
    expect(getToolEmoji('SomeNewTool')).toBe('⚙️')
  })
})

// --- getToolInputSummary ---

describe('getToolInputSummary', () => {
  it('extracts pattern for Glob', () => {
    expect(getToolInputSummary('Glob', { pattern: 'src/**/*.ts' })).toBe('src/**/*.ts')
  })

  it('extracts file_path for Read', () => {
    expect(getToolInputSummary('Read', { file_path: 'src/agent.ts' })).toBe('src/agent.ts')
  })

  it('extracts pattern for Grep', () => {
    expect(getToolInputSummary('Grep', { pattern: 'handleMessage' })).toBe('handleMessage')
  })

  it('extracts query for WebSearch', () => {
    expect(getToolInputSummary('WebSearch', { query: 'FRC swerve drive' })).toBe('FRC swerve drive')
  })

  it('extracts command for Bash', () => {
    expect(getToolInputSummary('Bash', { command: 'ls -la' })).toBe('ls -la')
  })

  it('truncates long file paths from the beginning', () => {
    const longPath = '/Users/mihai/dev/frc-feds/feds-central/fedsbot/src/some/deep/nested/agent.ts'
    const result = getToolInputSummary('Read', { file_path: longPath })
    expect(result).toHaveLength(50)
    expect(result).toMatch(/^\.\.\..*agent\.ts$/)
  })

  it('truncates long commands from the end', () => {
    const longCommand = 'npm run build && npm run test && npm run lint && npm run deploy --production'
    const result = getToolInputSummary('Bash', { command: longCommand })
    expect(result).toHaveLength(50)
    expect(result).toMatch(/\.\.\.$/)
  })

  it('returns empty string when key is missing', () => {
    expect(getToolInputSummary('Read', {})).toBe('')
  })

  it('falls back to JSON for unknown tools', () => {
    expect(getToolInputSummary('UnknownTool', { foo: 'bar' })).toBe('{"foo":"bar"}')
  })
})

// --- formatToolLine ---

describe('formatToolLine', () => {
  it('formats a completed tool', () => {
    const line = formatToolLine({ toolName: 'Glob', inputSummary: 'src/**/*.ts', elapsedSeconds: 1.2, done: true })
    expect(line).toContain('🔍')
    expect(line).toContain('Glob')
    expect(line).toContain('src/**/*.ts')
    expect(line).toContain('[1.2s]')
  })

  it('formats an in-progress tool', () => {
    const line = formatToolLine({ toolName: 'WebSearch', inputSummary: '"FRC swerve"', done: false })
    expect(line).toContain('🌐')
    expect(line).toContain('...')
    expect(line).not.toContain('[')
  })

  it('includes error text for failed tools', () => {
    const line = formatToolLine({
      toolName: 'Bash', inputSummary: 'npm test',
      elapsedSeconds: 2.5, done: true, error: 'Command exited with code 1',
    })
    expect(line).toContain('[2.5s]')
    expect(line).toContain('error: Command exited with code 1')
  })

  it('truncates long error messages to 50 characters', () => {
    const line = formatToolLine({
      toolName: 'Bash', inputSummary: 'npm test',
      elapsedSeconds: 2.5, done: true,
      error: 'This is a very long error message that should be truncated because it exceeds fifty characters by a lot',
    })
    const errorPart = line.split('error: ')[1]
    expect(errorPart.length).toBeLessThanOrEqual(50)
    expect(errorPart).toMatch(/\.\.\.$/)
  })
})

// --- handleToolEvent ---

describe('handleToolEvent', () => {
  function makeParts() {
    return []
  }

  it('creates a tool-call part on "tool" event', () => {
    const parts = makeParts()
    handleToolEvent(parts, 'tool', {
      toolUseId: 'tu-1',
      toolName: 'Glob',
      toolInput: { pattern: '**/*.ts' },
    })

    expect(parts).toHaveLength(1)
    expect(parts[0].type).toBe('tool-call')
    expect(parts[0].toolCallId).toBe('tu-1')
    expect(parts[0].toolName).toBe('Glob')
    expect(parts[0].inputSummary).toBe('**/*.ts')
    expect(parts[0].done).toBe(false)
    expect(parts[0].elapsedSeconds).toBeUndefined()
  })

  it('uses toolUseId from server, not a random UUID', () => {
    const parts = makeParts()
    handleToolEvent(parts, 'tool', {
      toolUseId: 'server-id-123',
      toolName: 'Read',
      toolInput: { file_path: 'foo.ts' },
    })
    expect(parts[0].toolCallId).toBe('server-id-123')
  })

  it('updates elapsedSeconds on "tool_progress" event', () => {
    const parts = [
      { type: 'tool-call', toolCallId: 'tu-1', toolName: 'Glob', done: false },
    ]
    handleToolEvent(parts, 'tool_progress', {
      toolUseId: 'tu-1',
      elapsedSeconds: 2.3,
    })
    expect(parts[0].elapsedSeconds).toBe(2.3)
  })

  it('ignores tool_progress for unknown toolUseId', () => {
    const parts = [
      { type: 'tool-call', toolCallId: 'tu-1', toolName: 'Glob', done: false },
    ]
    handleToolEvent(parts, 'tool_progress', {
      toolUseId: 'tu-999',
      elapsedSeconds: 5.0,
    })
    expect(parts[0].elapsedSeconds).toBeUndefined()
  })

  it('marks tool as done on "tool_done" event', () => {
    const parts = [
      { type: 'tool-call', toolCallId: 'tu-1', toolName: 'Glob', done: false },
    ]
    handleToolEvent(parts, 'tool_done', { toolUseId: 'tu-1', isError: false })
    expect(parts[0].done).toBe(true)
  })

  it('sets error on tool_done with isError', () => {
    const parts = [
      { type: 'tool-call', toolCallId: 'tu-1', toolName: 'Bash', done: false },
    ]
    handleToolEvent(parts, 'tool_done', {
      toolUseId: 'tu-1',
      isError: true,
      text: 'Permission denied',
    })
    expect(parts[0].done).toBe(true)
    expect(parts[0].error).toBe('Permission denied')
  })

  it('does not set error when isError is false', () => {
    const parts = [
      { type: 'tool-call', toolCallId: 'tu-1', toolName: 'Read', done: false },
    ]
    handleToolEvent(parts, 'tool_done', { toolUseId: 'tu-1', isError: false })
    expect(parts[0].error).toBeUndefined()
  })
})
