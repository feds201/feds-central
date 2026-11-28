// npm run eval -- <command> ...   (see "Evals" in fedsbot/README.md)
//   run <name> [--prompt-dir DIR] [--model M] [--effort E] [--ref COMMIT] [--reps 2] [--cases a,b] [--concurrency 4] [--max-usd 10]
//              runs the bot, judges, and prints the summary
//   judge <name> [--judge-model opus]   re-judge existing results
//   compare <name> [<name> ...]         table of summaries
import { parseArgs } from 'util';
import { runCases } from './run.js';
import { judge } from './judge.js';
import { printTable } from './summarize.js';

const { positionals, values } = parseArgs({
  allowPositionals: true,
  options: {
    'prompt-dir': { type: 'string' }, model: { type: 'string' }, effort: { type: 'string' }, ref: { type: 'string' },
    reps: { type: 'string', default: '2' }, cases: { type: 'string' }, concurrency: { type: 'string', default: '4' },
    'max-usd': { type: 'string', default: '10' }, 'judge-model': { type: 'string', default: 'opus' },
  },
});
const [command, ...names] = positionals;

if (command === 'run' && names.length === 1) {
  await runCases({
    name: names[0], reps: Number(values.reps), concurrency: Number(values.concurrency), maxUsd: Number(values['max-usd']),
    caseIds: values.cases?.split(','), promptDir: values['prompt-dir'], model: values.model, effort: values.effort, ref: values.ref,
  });
  await judge(names[0], values['judge-model']);
  printTable(names);
} else if (command === 'judge' && names.length === 1) {
  await judge(names[0], values['judge-model']);
  printTable(names);
} else if (command === 'compare' && names.length) {
  printTable(names);
} else {
  console.error('usage: npm run eval -- run <name> [options] | judge <name> | compare <name...>  (see fedsbot/README.md)');
  process.exit(1);
}
process.exit(0);
