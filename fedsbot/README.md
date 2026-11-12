# fedsbot

AI assistant Discord bot for The FEDS (FRC Team 201). Uses the Claude Agent SDK to answer student questions about the robot, game rules, and codebase in Discord threads.

## How It Works

### Discord — @mentions (channels)
1. Anyone @mentions the bot with a question in any channel
2. Bot creates a thread and starts a Claude Agent SDK session
3. AI reads the codebase and responds in the thread
4. Follow-up messages in the thread continue the same session (no @mention needed)

### Discord — DMs
1. Student sends the bot a direct message
2. Bot starts a new AI session and responds
3. Follow-ups continue the same session; a 30-minute gap starts a new conversation

### Web Chat API
- `POST /api/chat` — SSE endpoint for web chat clients
- Authenticated via `X-API-Key` header
- Supports session resumption via `sessionId` in the request body

### Auto-Deploy Webhook
- `POST /webhook/github` — receives GitHub push events
- On push to `main`: pulls latest code, and if `fedsbot/` files changed, runs `npm install` and restarts the service
- Verified via HMAC-SHA256 signature

### How the agent is configured
All of it is in `src/agent.ts`:
- **Model:** the `sonnet` alias, so the bot always runs the latest Sonnet the installed SDK knows about. Bump `@anthropic-ai/claude-agent-sdk` to pick up a newer one.
- **Prompt:** each session starts with the repo's `CLAUDE.md`, then `system-prompt-general.md`, then `system-prompt-discord.md` (Discord) or `system-prompt-chat.md` (web chat), then the user's message. Filesystem settings and other `CLAUDE.md` files are not loaded.
- **Tools:** Read, Glob, Grep, WebSearch, WebFetch, Bash, and Agent. A PreToolUse hook allows only Explore subagents and keeps them in the foreground, so the reply waits for their result.
- **Limits:** 15 turns per session.
- **Working directory:** the repo root, so the bot can read the whole monorepo. The repo's `.ignore` keeps its search tools (Grep, Glob) out of `fedsbot/evals/`, the eval answer keys. It's not a hard block: Bash or git history could still reach them, but that takes deliberate digging.

Before changing the prompt or any of the above, run the evals (below) and compare.

## Setup

### Prerequisites

- Node.js 20+ installed on your server
- Discord bot token ([create one here](https://discord.com/developers/applications))
- Anthropic API key ([get one here](https://platform.claude.com))
- Discord bot with the correct permissions (see [Discord Permissions](#discord-permissions) below)

### Discord Permissions

When creating the OAuth2 URL to add the bot to your server, you need the following:

**OAuth2 Scopes:**
- `bot`
- `applications.commands`

**Bot Permissions:**
| Permission | Reason |
|---|---|
| View Channels | See channels where students @mention the bot |
| Send Messages | Respond to questions in channels and DMs |
| Create Public Threads | Start a new thread for each question |
| Send Messages in Threads | Reply inside question threads |
| Read Message History | Detect DM conversation boundaries (30-min gap = new conversation) and collapse previous status embeds |
| Embed Links | Display rich status embeds showing AI thinking/tool progress |

**Privileged Gateway Intents (must be enabled in the [Discord Developer Portal](https://discord.com/developers/applications) > Bot settings):**
- **Message Content Intent** — read the actual text of messages so the bot can answer questions

The non-privileged intents (`Guilds`, `GuildMessages`, `DirectMessages`) are declared in `src/discord.ts` and work automatically.

### Installation

1. Install system dependencies (Alpine Linux):
   ```bash
   apk add git npm bash
   ```
   > `bash` is required by the Claude Agent SDK's Bash tool. Alpine doesn't include it by default.

2. Clone the feds-central repository:
   ```bash
   cd /root
   git clone https://github.com/feds201/feds-central.git
   ```

3. Install dependencies:
   ```bash
   cd /root/feds-central/fedsbot
   npm install
   ```

4. Create `.env` file (see `.env.example` for all variables and descriptions):
   ```bash
   cp .env.example .env
   nano .env  # Fill in your tokens
   ```

5. Test the bot:
   ```bash
   npm start
   ```

## Service Setup (Alpine Linux / OpenRC)

1. Copy new service file:
   ```bash
   cp /root/feds-central/fedsbot/fedsbot.openrc /etc/init.d/fedsbot
   chmod +x /etc/init.d/fedsbot
   ```

2. Start and enable (make sure to stop the server if you ran it yourself to test!):
   ```bash
   rc-service fedsbot start
   rc-update add fedsbot default
   ```

3. Manage:
   ```bash
   rc-service fedsbot status     # Check status
   rc-service fedsbot restart    # Restart (after code updates)
   tail -f /var/log/fedsbot.log  # View logs
   ```

## GitHub Webhook Setup

Configure at: https://github.com/feds201/feds-central/settings/hooks/595491205

1. Payload URL: `http://<your-server-ip>:<PORT>/webhook/github`
2. Content type: `application/json`
3. Secret: same value as `GITHUB_WEBHOOK_SECRET` in `.env`
4. Events: just "Pushes"

> **If you change `PORT`, the server IP, or `GITHUB_WEBHOOK_SECRET` in `.env`, you must also update the corresponding fields in the GitHub webhook settings above.**

## Environment Variables

See `.env.example` for the full list with descriptions.

## Evals

`evals/` measures how well the bot answers: 16 real student questions (from Discord history), each with a verified reference answer, scored by an Opus judge. Latest numbers: [`evals/RESULTS.md`](evals/RESULTS.md).

### Run
Needs a Claude login (`claude` CLI signed in) or `ANTHROPIC_API_KEY` exported in your shell (the eval doesn't read `.env`), plus `npm install`.
```bash
npm run eval -- run my-try                                  # the bot as it is in your working tree
npm run eval -- run my-prompt --prompt-dir path/to/prompts  # a folder with system-prompt-{general,discord,chat}.md
npm run eval -- run on-opus --model opus                    # also --effort low|medium|high
npm run eval -- run original --ref 8ce7b873                 # the bot as of any commit
npm run eval -- compare e1 my-try                           # table of saved results
```
Each `run` does 2 runs per case (`--reps`), then judges and prints correctness, fit, first-try rate, latency, tool calls and cost. Results go to `evals/results/<name>/` (gitignored). A full run costs about $1-2 for the bot plus about $0.75 for the judge, at API prices. `--max-usd` (default 10) stops a run early. `--cases a,b` runs only some cases; a run that stops resumes where it left off.

### How it works
- The bot runs in a temporary copy of the repo's files without `fedsbot/evals/` and without `.git`, with repo paths removed from its environment, so it can't read the answers, even through git history. (Only listing every running process on the machine would still show the real repo's path.) The copy is HEAD plus your working-tree `fedsbot/` (uncommitted changes elsewhere aren't included); `--ref` uses that commit's files as is. Copies live in `$TMPDIR/fedsbot-eval/`, and each run deletes any left behind by a run that died.
- A run that dies (rate limit, overload, network) isn't saved, so rerunning the same command retries it. A run that finishes without a good answer (e.g. it hit the turn limit) is saved and scored as a failure.
- Rerunning a name is refused if the settings, `src/agent.ts`, the prompts, the repo's `CLAUDE.md` or `package-lock.json` changed, so one name never mixes two versions of the bot.
- The judge gets `rubric.md`, `goldens.json` and the answers, shuffled under opaque ids with the planted answers from `controls.json` (reference answers that must score high, bad ones that must fail). If a control scores wrong, the run prints a warning; judge again before trusting it.
- Fit means the answer's shape and coaching: direct answers for direct questions, a plan for build tasks, one hint for bugs, no solution code, at most two questions. See `rubric.md`.
- Compare numbers from the same judge only. Differences under about 0.2 are noise.

### Add or change a case
1. Add the question to `cases.json` (`split`: `train` while tuning, `holdout` to check you're not overfitting).
2. Add its entry to `goldens.json`: `ideal_answer`, `shape`, `must_include`, `must_not`, with file paths and line numbers checked against the code.
3. Goldens go stale when the robot code changes. Re-check the ones that cite changed files.

## Troubleshooting

### Bot won't start
- Check environment variables: `cat .env`
- Check service status: `rc-service fedsbot status`
- View error logs: `tail -n 50 /var/log/fedsbot.log`

### Bot doesn't respond
- Check Discord permissions (see [Discord Permissions](#discord-permissions))
- Check logs for errors

### Session/thread issues
- Session mappings are stored in `sessions.json` — delete it to reset all conversations
- Each thread maps to one AI session for conversation context

## Security Notes

- Never commit `.env` to git (it's in .gitignore)
- Keep tokens private and use restrictive file permissions: `chmod 600 .env`
- The webhook endpoint verifies HMAC-SHA256 signatures
