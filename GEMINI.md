# FEDS 201 Central Repository

This is the monorepo for The FEDS (FRC Team 201), containing robot code, web applications, and documentation.

## 📂 Project Structure

- **`robot/`**: FRC robot code (Java/Gradle).
- **`dev-dashboard/`**: Developer dashboard web app (React/Node.js).
- **`fedsbot/`**: Discord AI assistant bot (TypeScript/Node.js).
- **`operations-manual/`**: Team documentation site (Next.js/MDX).
- **`scouting/`**: Scouting apps and data tools (Python/Mixed).
- **`game-manuals/`**: FRC game manuals.

## 🤖 Robot Code (`robot/2026-rebuilt`)

The robot code for the 2026 game "REBUILT". Built with WPILib and GradleRIO.

**Key Commands (run from `robot/2026-rebuilt/`):**

| Command | Description |
|---|---|
| `./gradlew build` | Compile and run tests |
| `./gradlew deploy` | Deploy code to the robot |
| `./gradlew simulateJava` | Run robot simulation (Glass + DS) |
| `./gradlew test` | Run unit tests |

**Simulation:**
The project uses a dual-engine simulation (MapleSim + ODE4J). Run `./gradlew simulateJava` to start.

## 🖥️ Developer Dashboard (`dev-dashboard/`)

A React-based dashboard for team developers.

**Tech Stack:** React, Vite, Tailwind CSS, Node.js (Express), PostgreSQL (Neon), Supabase.

**Key Commands (run from `dev-dashboard/`):**

- `npm install`: Install dependencies.
- `npm run dev`: Start the frontend development server.
- `npm run server`: Start the backend server (in `server/` directory).
- `npm run build`: Build the frontend for production.

## 🤖 FEDS Bot (`fedsbot/`)

AI assistant Discord bot using Claude Agent SDK.

**Tech Stack:** TypeScript, Node.js, Discord.js, Anthropic API.

**Key Commands (run from `fedsbot/`):**

- `npm install`: Install dependencies.
- `npm start`: Start the bot.
- `npm run dev`: Start the bot in watch mode.

## 📚 Operations Manual (`operations-manual/`)

The team's handbook and documentation site.

**Tech Stack:** Next.js, Nextra, MDX.

**Key Commands (run from `operations-manual/`):**

- `npm install`: Install dependencies.
- `npm run dev`: Start the development server.
- `npm run build`: Build the static site.

## 🛠️ Contribution Workflow

1.  **Branching:** Create a new branch for your feature or fix.
2.  **Commits:** Make small, focused commits with descriptive messages.
3.  **Pull Requests:** Submit a PR once a logical unit of work is complete.
4.  **AI Review:** Wait for the automated AI review and address feedback.
5.  **Peer Review:** Request a review from a team member.
6.  **Merge:** Merge into `main` after approval and passing checks.

## ⚠️ Important Notes

- **Secrets:** Never commit `.env` files or API keys.
- **Testing:** Always test your code locally (unit tests or simulation) before pushing.
