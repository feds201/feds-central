# 🚀 FEDS 201 Scouting Learning

---

# 🛑 WARNING

This is a **learning subsystem**.

**DO NOT push production code here.**  
**DO NOT submit this branch.**

This repository exists for:
- Education  
- Practice  
- Making mistakes safely  
- Learning how our scouting architecture works  

---

# 📘 Welcome

Welcome to the **FEDS 201 Scouting Learning Codebase**.

This environment is designed to help you understand:

- How our data collection works  
- How match data flows to the database  
- How the UI connects to backend logic  
- How scouting architecture is structured  

---

# 📁 Repository Structure

```
scouting/android/              → Main Flutter/Dart mobile scouting app  
scouting/server/               → Backend services for data storage and retrieval  
scouting/database/             → Database schemas and related code  
scouting/data-source/          → Data source integrations  
scouting/data-chunk/           → Data chunking utilities  
scouting/desktop-client/       → Desktop client application  
scouting/scan/                 → QR code / scanning functionality  
scouting/pits/                 → Pit scouting tools  
scouting/autos/                → Autonomous routine data  
scouting/pyintel-integrations/ → Python/Intel integrations  
scouting/old-yearly/           → Historical scouting code (2020–2024)  
```

---

# 💡 Tips for New Contributors

### ✅ Don’t Be Afraid to Ask Questions
Data structures and database schemas can feel confusing at first.

### ✅ Start Small
- Fix a UI typo  
- Update a scouting metric  
- Add comments to a complex function  

### ✅ Read the Manual
Understand the game rules before writing scouting logic.

If you don’t understand the metric,
you won’t store it correctly.

### ✅ Test Locally First
Always run and test your code before proposing changes.

### ✅ Commit Often
Small commits are much easier to review than one massive commit.

---

# 🛠 The Scouting Learning Challenge

We’ve intentionally left **multiple levels of errors** in the code.

Your job is to find and fix them.

This is how you move from:

Reading code  
➡ Understanding code  
➡ Improving code  

---

# 🔴 Level 1 — The Glitchy Timer

### 📂 File
```
scouting/android/lib/Match_Pages/match/Auton.dart
```

### 🎯 Mission
During Autonomous mode,  
the timer does NOT reset properly when a new match starts.

### 🔧 Fix
Find the **single line of code** responsible for resetting the timer  
and correct the logic.

---

# 🟠 Level 2 — The Missing Input

### 📂 File
```
scouting/android/lib/Match_Pages/match/TeleOperated.dart
```

### 🎯 Mission
Scouts cannot log data when a robot becomes **Inactive**.

### 🔧 Fix
- Look at the different sub-pages  
- Find the **Inactive1 page**  
- Add the missing **button widget**  
- Allow scouts to log robot downtime  

---

# 🟡 Level 3 — The Data Boss

### 📂 Files
```
scouting/android/lib/Match_Pages/match/EndGame.dart  
scouting/android/lib/services/DataBase.dart
```

### 🎯 Mission
The variable:

```
endGameActions
```

is supposed to increment when actions are logged.

It stays stuck at zero.

### 🔧 Fix

1. Fix the increment logic in **EndGame.dart**
2. Ensure the data is handled properly in **DataBase.dart**

### ⭐ Bonus Bug
After fixing Level 3,
a small bug appears in:

```
scouting/android/lib/Match_Pages/match_page.dart
```

Find it.  
Fix it.  
Complete the challenge.

---

# 🟢 Level 4 — The Creative Engineer (NEW)

Now build something new.

---

## 🎯 Your Mission

Add a new feature to the scouting app.

### Examples

- A new button  
- A checkbox  
- A counter  
- A dropdown  
- A UI improvement  
- A small quality-of-life feature  

---

## 🧠 Requirements

Your feature must:

- Compile successfully  
- Store data properly (if needed)  
- Make sense within game rules  
- Fit cleanly into the architecture  

---

## 📬 When Finished

Create a Pull Request.

In your PR description, explain:

- What you changed  
- Why you changed it  
- What you learned about the architecture  

David will review it and provide feedback.

---

# 🤖 AI Policy & FEDSBot Usage

This is a learning repository.

You are strongly encouraged NOT to use:

- ChatGPT  
- Claude  
- GitHub Copilot  

The goal is to build debugging skills.

---

## If You Get Stuck

1. Use FEDSBot first  
2. If that fails, contact David  

---

# 🌐 FEDSBot

Go to:

https://developer.feds201.com/chat

---

## ❌ Bad Question
Write the fix for Level 3.

## ✅ Good Question
I’m on branch `learning_scouting_james`.  
I’m editing `EndGame.dart`.  
My variable is not incrementing.  
Should this be inside `setState()`?

Ask for:
- Advice  
- Hints  
- Explanation  
- Debugging guidance  

Not full solutions.

---

# 🚀 Practice Workflow

---

## 1️⃣ Create Your Own Branch

Always branch off the main learning branch.

Format:

```
learning_scouting_yourname
```

Example:

```
git checkout -b learning_scouting_james
```

---

## 2️⃣ Make Your Changes Locally

Write your code.  
Test it thoroughly.  
Work through all four levels.

---

## 3️⃣ Commit Your Work

Use clear commit messages.

Example:

```
git commit -m "Fixed Level 1 timer reset logic"
```

Small commits > Giant commits.

---

## 4️⃣ Create a Practice Pull Request

Explain:

- What you changed  
- Why you changed it  
- What you learned  

If you don’t know how to create a PR, search:

```
How to create a pull request on GitHub
```

---

## 5️⃣ Wait for Review

- FEDSBot may give automated feedback  
- A senior scout or programmer will review  
- Read feedback carefully  

That’s where real learning happens.

---

# 🎯 Final Reminder

This branch is for:

Learning  
Debugging  
Experimenting  
Understanding architecture  

Not production deployment.

Build skills.  
Ask questions.  
Make mistakes safely.

🚀
