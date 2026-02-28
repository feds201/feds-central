**FEDS 201's Scouting Learning**

🛑 **WARNING:** This is a **learning subsystem**. **DO NOT push any code here. DO NOT SUBMIT.** 🛑

Welcome to the **FEDS 201 Scouting Learning codebase!**

This repository is strictly for **educational purposes**, **practice**, and **making mistakes safely** as we develop our **data collection** and **analysis tools**.

📁 **Repository Structure**
Path	Description
scouting/android/	**Main Flutter/Dart mobile scouting app**
scouting/server/	**Backend services for data storage and retrieval**
scouting/database/	**Database schemas and related code**
scouting/data-source/	**Data source integrations**
scouting/data-chunk/	**Data chunking utilities**
scouting/desktop-client/	**Desktop client application**
scouting/scan/	**QR code / scanning functionality**
scouting/pits/	**Pit scouting tools**
scouting/autos/	**Autonomous routine data**
scouting/pyintel-intergrations/	**Python/Intel integrations**
scouting/old-yearly/	**Historical scouting code from previous FRC seasons (2020–2024)**

💡 **Tips for New Contributors**

- **Don't be afraid to ask questions!** Data structures and database schemas can be tricky at first.
- **Start small** — Fix a **UI typo**, update a **scouting metric**, or add a **comment** to a complex function.
- **Read the Manual** — Before writing scouting code, understand the **game rules** so you know exactly what metrics actually mean.
- **Test locally first** — Practice running your code on your own machine before proposing changes.
- **Commit often** — Small, frequent commits are much easier for mentors to review than one giant "finished" block.

🛠️ **The Scouting Learning Challenge**

To help you get hands-on with the codebase, we've intentionally left **multiple levels of errors** for you to find and fix.

This is the best way to move from **reading the code** to **understanding how it all connects**.

🔴 **Level 1: The Glitchy Timer**

**File:**
scouting/android/lib/Match_Pages/match/Auton.dart

**The Mission:**
During **Autonomous mode**, the **timer isn't resetting properly** when a new match starts.

**The Fix:**
Find the **single line of code** responsible for the **timer reset** and correct the logic.

🟠 **Level 2: The Missing Input**

**File:**
scouting/android/lib/Match_Pages/match/TeleOperated.dart

**The Mission:**
Our **strategy team** noticed they can't **log data** when a robot goes "**Inactive.**"

**The Fix:**
Look into the different "**sub-pages**" within this file. Locate the **Inactive1 page** and add the **missing button widget** so scouts can report **robot downtime**.

🟡 **Level 3: The Data Boss**

**Files:**
scouting/android/lib/Match_Pages/match/EndGame.dart  
scouting/android/lib/services/DataBase.dart

**The Mission:**
The variable **endGameActions** is broken — it's supposed to **increment** every time a scout logs an action, but the number stays **stuck at zero**!

**The Fix:**
- Fix the **increment logic** in **EndGame.dart**.  
- Ensure the **data** is actually being handled correctly in **DataBase.dart**.  
- **Bonus:** Once those are fixed, a minor **bug** will appear in  
scouting/android/lib/Match_Pages/match_page.dart — find it and **squash it** to complete the challenge!

🟢 **Level 4: The Creative Engineer (NEW)**

After completing Level 3, it's time to **build something new**.

🎯 **The Mission**
Add a **new feature** of your choice to the **scouting app**.

**Examples:**
- Add a **new button**  
- Add a **checkbox**  
- Add a **counter**  
- Add a **dropdown**  
- Improve **layout/UI**  
- Add a **small quality-of-life feature** for scouts

**Be creative** — but make sure it:
- **Compiles**  
- **Stores data properly** (if needed)  
- **Makes sense** within the **game rules**

🧠 **The Goal**
This level is about:
- Understanding how **widgets connect**  
- Seeing how **data flows** to the **database**  
- Practicing **clean architecture**

Once complete:
- Create a **PR**  
- Explain your **idea** and **design choices**  
- **David** will review it and give feedback

🤖 **AI Policy & FEDSBot Usage**
This is a **learning repository**.  

You are encouraged **NOT** to use **external AI tools** such as:
- ChatGPT
- Claude
- GitHub Copilot

The goal is to **build your own debugging and architecture skills**.

If you truly get stuck:
- Use **FEDSBot first**  
- If that still doesn’t help, contact **David directly**

✅ **How to Use FEDSBot Properly**
Go to:  
https://developer.feds201.com/chat

**Do NOT** ask it to **write the code** for you.  

Instead, explain:
- Which **branch** you are on  
- Which **file** you are editing  
- What you are trying to do  
- What is **not working**

Ask for:
- **Advice**  
- **Hints**  
- **Explanation**  
- **Debugging guidance**

❌ **Bad Question:**  
“Write the fix for Level 3.”

✅ **Good Question:**  
“I’m on branch **learning_scouting_james**, editing **EndGame.dart**. My variable isn’t incrementing. Should this be inside **setState()**?”

The goal is to **understand how the scouting app works** — not to copy-paste solutions.

🚀 **Practice Workflow**
1️⃣ **Create Your Own Branch**  
Before making any changes, create a **personal branch** off the main learning branch.  
Format:  
`learning_scouting_yourname`  
Example:  
`git checkout -b learning_scouting_james`

2️⃣ **Make Your Changes Locally**  
Write your **code** and **test it thoroughly**.  
Work through the **four levels of challenges** listed above.

3️⃣ **Commit Your Work**  
Use **clear, descriptive commit messages**.  
Example:  
`git commit -m "Fixed Level 1 timer reset logic"`  
Small commits are much easier to review than one **giant commit**.

4️⃣ **Create a Practice Pull Request (PR)**  
Propose your **changes** to the team.  
In your **PR description**, explain:
- What you **changed**  
- Why you **changed** it  
- What you **learned** about the **scouting app’s architecture**

If you are unfamiliar with pull requests, search YouTube for:  
**"How to create a pull request on GitHub"**

5️⃣ **Wait for Review**  
- **FEDSBot** may provide automated feedback  
- A **senior scout, programmer, or David** will review your logic  
- **Read feedback carefully** — that’s where real learning happens.
