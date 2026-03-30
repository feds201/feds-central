# Fedsbot

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
- `POST /api/chat` — SSE endpoint used by the dev dashboard
- Authenticated via `X-API-Key` header
- Supports session resumption via `sessionId` in the request body

### Auto-Deploy Webhook
- `POST /webhook/github` — receives GitHub push events
- On push to `main`: pulls latest code, and if `fedsbot/` files changed, runs `npm install` and restarts the service
- Verified via HMAC-SHA256 signature

## Setup

### Prerequisites

- Node.js 20+ installed on your server
- Discord bot token ([create one here](https://discord.com/developers/applications))
- Anthropic API key ([get one here](https://platform.claude.com))
- Discord bot intents and permissions — see `src/discord.ts` for the exact intents/partials declared in code

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

## Troubleshooting

### Bot won't start
- Check environment variables: `cat .env`
- Check service status: `rc-service fedsbot status`
- View error logs: `tail -n 50 /var/log/fedsbot.log`

### Bot doesn't respond
- Check Discord permissions (see `src/discord.ts` for required intents)
- Check logs for errors

### Session/thread issues
- Session mappings are stored in `sessions.json` — delete it to reset all conversations
- Each thread maps to one AI session for conversation context

## Security Notes

- Never commit `.env` to git (it's in .gitignore)
- Keep tokens private and use restrictive file permissions: `chmod 600 .env`
- The webhook endpoint verifies HMAC-SHA256 signatures
