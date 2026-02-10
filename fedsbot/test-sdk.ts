import { unstable_v2_createSession } from '@anthropic-ai/claude-agent-sdk';
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: path.join(__dirname, '.env') });

// Same as agent.ts: clear tsx hooks so SDK subprocess is clean
delete process.env.NODE_OPTIONS;

const repoRoot = path.resolve(__dirname, '..');
process.chdir(repoRoot);
console.log(`cwd: ${process.cwd()}`);

const session = unstable_v2_createSession({
  model: 'claude-sonnet-4-5',
  tools: ['Bash', 'Glob', 'Read', 'Grep'],
  allowedTools: ['Bash', 'Glob', 'Read', 'Grep'],
  permissionMode: 'acceptEdits' as const,
  maxTurns: 10,
});

const prompt = 'List all top-level files and directories in the current working directory. Use `ls` via the Bash tool.';

console.log(`\nSending: "${prompt}"\n`);
console.log('='.repeat(60));

await session.send(prompt);

for await (const msg of session.stream()) {
  if (msg.type === 'assistant') {
    const content = (msg as any).message?.content;
    if (Array.isArray(content)) {
      for (const block of content) {
        if (block.type === 'text') {
          console.log(`\n[TEXT] ${block.text}`);
        } else if (block.type === 'tool_use') {
          console.log(`\n[TOOL_USE] ${block.name}`, JSON.stringify(block.input, null, 2));
        }
      }
    }
  } else if (msg.type === 'tool') {
    // Tool result events
    const t = msg as any;
    const content = t.message?.content;
    if (Array.isArray(content)) {
      for (const block of content) {
        if (block.type === 'tool_result') {
          const output = typeof block.content === 'string' ? block.content : JSON.stringify(block.content);
          const preview = output.length > 500 ? output.slice(0, 500) + `... [TRUNCATED, total ${output.length} chars]` : output;
          console.log(`\n[TOOL_RESULT] id=${block.tool_use_id} error=${block.is_error ?? false}`);
          console.log(preview);
        }
      }
    } else {
      // Dump raw if unexpected shape
      console.log(`\n[TOOL_RAW]`, JSON.stringify(msg, null, 2).slice(0, 800));
    }
  } else if (msg.type === 'result') {
    const r = msg as any;
    console.log('\n' + '='.repeat(60));
    console.log(`[RESULT] is_error=${r.is_error}`);
    console.log(r.result);
  } else {
    // Log anything else we don't expect
    console.log(`\n[${msg.type}]`, JSON.stringify(msg, null, 2).slice(0, 300));
  }
}

session.close();
console.log('\nDone.');
