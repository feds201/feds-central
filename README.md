# FEDS 201 Central Repository

Welcome to the FEDS 201 central codebase! This repository contains everything our team builds: robot code, scouting apps, documentation, and more.

## 📁 Repository Structure

Here's what lives where:

- **`robot/`** - All robot code for each season
  - `template/` - Starting template for new seasons
  - `<year>-<game>/` - The robot code for this season!
- **`scouting/`** - Scouting apps and data tools
  - `old-years/` - scouting app code from back when we made a new copy every year
- **`dev-dashboard/`** - Dashboard for programmers, live at: [developer.feds201.com](https://developer.feds201.com/)
- **`operations-manual/`** - Team documentation, live at [operational-manual.feds201.com](https://operational-manual.feds201.com/)
- **`fedsbot/`** - Server running on Linode. Implements @FEDSBot Discord bot, and the backend used by the FEDSBot chat in dev-dashboard/
- **`game-manuals/`** - FRC game manuals and resources (useful for AI bot/code review to understand this year's game)

---

## 💡 Tips for New Contributors

- **Don't be afraid to ask questions!** Everyone was new once.
- **Start small** - Fix a typo, add a comment, or make a small improvement
- **Read existing code** before making big changes
- **Test locally first** - Never push code you haven't tested
- **Commit often** - Small, frequent commits are better than huge ones

---

## 🚀 Contributing Code

New to contributing? No worries! Here's the workflow:

### 1. Make Your Changes Locally

- Write your code and test it thoroughly
- Make small, focused commits as you go 
  - avoid having one huge commit!
- Commit messages should describe what you did 
  - good message: "Add autonomous mode for coral scoring" or "Tuned auton parameters"
  - bad message: "Did the thing" (What thing??)

### 2. Make Sure Everything Works

- Test your code multiple times!
- Make sure you didn't break anything else!

### 3. Create a Pull Request (PR)

A pull request is how you propose your changes to the team. [New to PRs? Watch this video](https://www.youtube.com/watch?v=nCKdihvneS0).
Once you finish a logical unit of work, submit a pull request.

**Good PR practices:**

- Write a clear title explaining what your PR does
- In the description, explain:
  - **What** you changed
  - **Why** you changed it
  - **How** to test it
- Keep PRs focused on one thing (don't mix unrelated changes)

### 4. Wait for AI Review

Our repository has automated AI review that will check your code and give you feedback. Read the comments and address any concerns.

### 5. Get a Teammate Review (Recommended)

Ask a senior team member or mentor to review your code. They might catch things the AI missed or suggest improvements.

### 6. Merge It

Once your PR is approved and all checks pass, you can merge it into the main branch.
