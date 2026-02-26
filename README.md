# FEDS 201's Scouting Learning
> 🛑 **WARNING: This is a learning subsystem. DO NOT push any code here. DO NOT SUBMIT.** 🛑

Welcome to the FEDS 201's Scouting Learning codebase! This repository is strictly for educational purposes, practice, and making mistakes safely as we develop our data collection and analysis tools.

---

## 📁 Repository Structure

| Path | Description |
|------|-------------|
| `scouting/android/` | Main Flutter/Dart mobile scouting app |
| `scouting/server/` | Backend services for data storage and retrieval |
| `scouting/database/` | Database schemas and related code |
| `scouting/data-source/` | Data source integrations |
| `scouting/data-chunk/` | Data chunking utilities |
| `scouting/desktop-client/` | Desktop client application |
| `scouting/scan/` | QR code / scanning functionality |
| `scouting/pits/` | Pit scouting tools |
| `scouting/autos/` | Autonomous routine data |
| `scouting/pyintel-intergrations/` | Python/Intel integrations |
| `scouting/old-yearly/` | Historical scouting code from previous FRC seasons (2020–2024) |

---

## 💡 Tips for New Contributors

- **Don't be afraid to ask questions!** Data structures and database schemas can be tricky at first.
- **Start small** — Fix a UI typo, update a scouting metric, or add a comment to a complex function.
- **Read the Manual** — Before writing scouting code, understand the game rules so you know exactly what metrics actually mean.
- **Test locally first** — Practice running your code on your own machine before proposing changes.
- **Commit often** — Small, frequent commits are much easier for mentors to review than one giant "finished" block.

---

## 🛠️ The Scouting Learning Challenge

To help you get hands-on with the codebase, we've intentionally left three levels of errors for you to find and fix. This is the best way to move from *reading* the code to *understanding* how it all connects.

---

### 🔴 Level 1: The Glitchy Timer

**File:** `scouting/android/lib/Match_Pages/match/Auton.dart`

**The Mission:** During Autonomous mode, the timer isn't resetting properly when a new match starts.

**The Fix:** Find the single line of code responsible for the timer reset and correct the logic.

---

### 🟠 Level 2: The Missing Input

**File:** `scouting/android/lib/Match_Pages/match/TeleOperated.dart`

**The Mission:** Our strategy team noticed they can't log data when a robot goes "Inactive."

**The Fix:** Look into the different "sub-pages" within this file. Locate the `Inactive1` page and add the missing button widget so scouts can report robot downtime.

---

### 🟡 Level 3: The Data Boss

**Files:**
- `scouting/android/lib/Match_Pages/match/EndGame.dart`
- `scouting/android/lib/services/DataBase.dart`

**The Mission:** The variable `endGameActions` is broken — it's supposed to increment (count up) every time a scout logs an action, but the number stays stuck at zero!

**The Fix:**
1. Fix the increment logic in `EndGame.dart`.
2. Ensure the data is actually being handled correctly in `DataBase.dart`.
3. **Bonus:** Once those are fixed, a minor bug will appear in `scouting/android/lib/Match_Pages/match_page.dart` — find it and squash it to complete the challenge!

---

## 🤖 A Note on Using AI & FEDSBot

You are absolutely welcome (and encouraged!) to use tools like ChatGPT, Claude, or our own **@FEDSBot** to help explain snippets of code or suggest fixes.

However, keep this in mind: **This is not a competition.** The goal isn't just to have working code — the goal is for you to *understand* how the scouting app works. If an AI gives you an answer, try to reverse-engineer it. Ask yourself:

> *"Why did this variable need to be an integer instead of a string?"*
> *"How does this function call affect the database?"*

---

## 🚀 Practice Workflow

1. **Create Your Own Branch** — Before making any changes, create a personal branch off the main learning branch. Use the format `learning_scouting_yourname`.
   `git checkout -b learning_scouting_james`

2. **Make Your Changes Locally** — Write your code and test it thoroughly. Work through the three levels of challenges listed above.

3. **Commit Your Work** — Use clear, descriptive messages so others know which level you solved.
   Example: `git commit -m "Fixed Level 1 timer reset logic"`

4. **Create a Practice Pull Request (PR)** — Propose your changes to the team. In your PR description, explain what you learned about the scouting app's architecture while fixing the bug.

5. **Wait for AI & Teammate Review** — Read the automated feedback from our AI reviewer and ask a senior scout or programmer to look over your logic!
