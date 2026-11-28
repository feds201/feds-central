# fedsbot: notes for anyone changing the bot

- How the bot is set up (model, prompt, tools, subagent hook): "How the agent is configured" in `README.md`.
- Any change to the prompts (`system-prompt-*.md`) or to `src/agent.ts` options can change answer quality. Run the evals before and after and compare (`README.md` → "Evals"):
  ```bash
  npm run eval -- run before --ref HEAD
  npm run eval -- run after
  npm run eval -- compare before after
  ```
  Ship only if correctness and fit hold or improve and latency doesn't jump. Differences under about 0.2 are noise; use `--reps 3` when it's close.
- Don't tune the prompt to the eval questions (no case-specific facts in the prompt). Check the holdout cases.
- `fedsbot/evals/` holds the answer keys. Eval runs use a copy of the repo without it (and without `.git`). In production the repo's `.ignore` keeps the bot's search tools out of it; Bash could still reach it, so don't put anything secret there.
- Tests and types: `npm test`, `npm run typecheck`.
