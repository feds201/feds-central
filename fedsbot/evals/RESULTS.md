# Eval results

Scored with the committed judge (`npm run eval -- judge <name>`) on the 16 cases in `cases.json`. Every bundle's 7 planted controls scored as expected.

| | Before this PR (`original`) | Now (`e1`) |
|---|---|---|
| Setup | original prompt, SDK 0.2.37, `claude-sonnet-5`, Haiku 4.5 subagents | `system-prompt-general.md` (E1), SDK 0.3.322, `sonnet` (Sonnet 5.5) |
| Runs | 32 (2 per case) | 48 (3 per case) |
| Correctness (0-5) | 3.47 | **4.23** |
| Fit (0-5) | 2.72 | **3.92** |
| Holdout correctness / fit | 3.50 / 2.42 | **4.44 / 3.72** |
| Satisfied first try | 50% | **96%** |
| Failed | 13% | **2%** |
| Median time to a satisfying answer | 68 s | **9.5 s** |
| Median tool calls | 18.5 | **3** |
| Cost per answer | $0.16+ (the old SDK under-logs output tokens) | **$0.03** |

To reproduce: `npm run eval -- run original --ref 8ce7b873` and `npm run eval -- run e1 --reps 3`.

## How E1 was picked

Two hill climbs on Sonnet 5.5, scored by an Opus judge that ran as a long-lived subagent. Its numbers are about 0.2-0.4 higher than the committed judge's, so compare runs only within one judge.

1. **Small additions** to the original prompt, one per round, kept only if the score went up. The best (R4, in `prompts/r4/`) added length and shape rules, repo grounding, no bug lists, and a check that code is actually used. The same prompt on Opus 5.5 was a little more correct but 2.7x slower; on Sonnet 5 it was worse and 5x slower.
2. **Full rewrite** after the rubric was tightened (questions capped, light debugging hints). It started from a minimal prompt (identity + off-topic rule only) and added sections one at a time, then tried four full rewrites and combined the best:
   - The minimal prompt hands over solution code and bug lists and writes walls of text.
   - Explicit "no bug lists" and "the reason it doesn't run *is* the bug" rules were what fixed the mentor and debugging cases.
   - Examples didn't help. Low effort was cheaper but less correct.
   - E1 = the principles rewrite + the bug-hunt rules + "don't announce what you won't do" + "search the whole repo before saying something doesn't exist".

## Known weak spots in E1

- Scouting "add a question" answers often skip the scanner app and the CSV column order.
- The game-rule number is sometimes wrong (G420 is right for tower contact).
- The IO-layers answer can run past Discord's 1900 characters.
