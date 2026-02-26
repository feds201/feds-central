# FEDS 201's Scouting Learning

> **🛑 WARNING: This is a learning subsystem. DO NOT push any code here. DO NOT SUBMIT. 🛑**

Welcome to the FEDS 201's Scouting Learning codebase! This repository is strictly for educational purposes, practice, and making mistakes safely. 

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
- **Test locally first** - Practice running your code on your own machine
- **Commit often** - Small, frequent commits are better than huge ones

---

## 🚀 Practice Workflow 

New to contributing? Here is the workflow to practice (Remember: **DO NOT SUBMIT** to the main production branches!):

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

### 3. Create a Practice Pull Request (PR)

A pull request is how you propose your changes to the team. [New to PRs? Watch this video](https://www.youtube.com/watch?v=nCKdihvneS0).
Once you finish a logical unit of work, you can draft a PR to see how the system works.

**Good PR practices:**

- Write a clear title explaining what your PR does
- In the description, explain:
  - **What** you changed
  - **Why** you changed it
  - **How** to test it
- Keep PRs focused on one thing (don't mix unrelated changes)

### 4. Wait for AI Review

Our repository has automated AI review that will check your code and give you feedback. Read the comments and address any concerns to learn from the feedback.

### 5. Get a Teammate Review (Recommended)

Ask a senior team member or mentor to review your code. They might catch things the AI missed or suggest improvements.
