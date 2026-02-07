# Discord Bot Setup Guide

This guide will help you set up the Discord bot integration for the FEDS dev dashboard.

## Prerequisites

- A Discord server where you have admin permissions
- GitHub repository with Actions enabled
- The GitHub secrets already set up (`CLAUDE_CODE_OAUTH_TOKEN`, `DISCORD_BOT_TOKEN`)

---

## Step 1: Create a Discord Bot

### 1.1 Go to Discord Developer Portal
Visit: https://discord.com/developers/applications

### 1.2 Create New Application
1. Click "New Application"
2. Name it something like "FEDS Claude Bot"
3. Click "Create"

### 1.3 Create a Bot User
1. In the left sidebar, click "Bot"
2. Click "Add Bot" → "Yes, do it!"
3. Under "Privileged Gateway Intents", enable:
   - ✅ **Message Content Intent** (required to read message content)
   - ✅ **Server Members Intent** (optional, but recommended)

### 1.4 Get Your Bot Token
1. Under the bot's username, click "Reset Token"
2. Copy the token (you'll need this for `.env`)
3. **IMPORTANT:** Never share this token publicly!

### 1.5 Invite Bot to Your Server
1. Go to "OAuth2" → "URL Generator" in the left sidebar
2. Under "Scopes", select:
   - ✅ `bot`
3. Under "Bot Permissions", select:
   - ✅ Read Messages/View Channels
   - ✅ Send Messages
   - ✅ Read Message History
   - ✅ Add Reactions
4. Copy the generated URL at the bottom
5. Open it in a browser and add the bot to your Discord server

---

## Step 2: Create a GitHub Personal Access Token

### 2.1 Go to GitHub Settings
Visit: https://github.com/settings/tokens

### 2.2 Create New Token
1. Click "Generate new token" → "Generate new token (classic)"
2. Name: "Discord Bot Workflow Trigger"
3. Select scopes:
   - ✅ `repo` (Full control of private repositories)
   - ✅ `workflow` (Update GitHub Action workflows)
4. Click "Generate token"
5. **Copy the token** (you won't see it again!)

---

## Step 3: Configure Environment Variables

### 3.1 Update `.env` file
In `dev-dashboard/.env`, add:

```bash
# Discord Bot Configuration
DISCORD_BOT_TOKEN=your_actual_discord_bot_token_here
GITHUB_TOKEN=your_github_personal_access_token_here
GITHUB_OWNER=your-github-username
GITHUB_REPO=feds-central
```

Replace:
- `your_actual_discord_bot_token_here` with the token from Step 1.4
- `your_github_personal_access_token_here` with the token from Step 2.2
- `your-github-username` with your actual GitHub username

### 3.2 Add GitHub Secret
The workflow also needs `DISCORD_BOT_TOKEN` as a GitHub secret:

1. Go to your repo: `https://github.com/YOUR_USERNAME/feds-central/settings/secrets/actions`
2. Click "New repository secret"
3. Name: `DISCORD_BOT_TOKEN`
4. Value: Your Discord bot token (same as in `.env`)
5. Click "Add secret"

---

## Step 4: Launch and Test

### 4.1 Start the Server
```bash
cd dev-dashboard/server
npm run dev
```

You should see:
```
Server running on http://localhost:3000
✅ Discord bot logged in as FEDS Claude Bot#1234
```

If you see warnings like "DISCORD_BOT_TOKEN not set", check your `.env` file.

### 4.2 Test in Discord
1. Go to your Discord server
2. In any channel where the bot has access, type:
   ```
   @FEDS Claude Bot what is a PID controller?
   ```
3. The bot should:
   - React with ⏳ (hourglass)
   - Trigger the GitHub workflow
   - The workflow runs Claude and replies to your message
   - Bot changes reaction to ✅ (checkmark)

### 4.3 Check GitHub Actions
Visit: `https://github.com/YOUR_USERNAME/feds-central/actions`

You should see a "Discord Claude Code Q&A" workflow run triggered by `workflow_dispatch`.

---

## Troubleshooting

### Bot doesn't respond
- Check that the bot is online in Discord (green dot next to name)
- Check server logs for errors
- Verify `DISCORD_BOT_TOKEN` is correct in `.env`
- Make sure you **@ mentioned** the bot (just typing the name won't work)

### Workflow doesn't trigger
- Check `GITHUB_TOKEN` has `workflow` scope
- Verify `GITHUB_OWNER` and `GITHUB_REPO` are correct in `.env`
- Check GitHub Actions tab for error messages

### Bot crashes on startup
- Make sure you ran `npm install` in the `server/` directory
- Check that all environment variables are set
- Look at the error message in the console

### "Message Content Intent" error
- Go back to Discord Developer Portal
- Enable "Message Content Intent" under Bot settings
- Restart your server

---

## Production Deployment

When deploying to production (Linode, Heroku, etc.):

1. Set all environment variables in your hosting platform
2. Change `NODE_ENV=production`
3. Make sure the server stays running (use PM2 or similar)
4. Consider using a process manager for auto-restart on crashes

---

## How It Works

1. Student mentions `@FEDS Claude Bot` in Discord with a question
2. Bot receives the message and extracts the question
3. Bot triggers the GitHub Actions workflow via GitHub API
4. Workflow:
   - Checks out the repo
   - Runs Claude with the question (in mentor mode)
   - Posts Claude's response back to Discord as a reply
5. Student gets mentoring/guidance instead of direct answers

---

## Security Notes

- Never commit `.env` file to git (it's already in `.gitignore`)
- Keep bot token and GitHub token secret
- The bot only responds to @mentions (won't spam channels)
- Mentor mode is enforced via system prompt in the workflow
