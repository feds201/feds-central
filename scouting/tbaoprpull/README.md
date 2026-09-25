# TBA OPR Pull

Pulls scored qualification matches for a TBA event, calculates team OPR-style stats, and writes them to Neon.

Run this during/after the event when TBA has scored match data and the scouting database should be refreshed. On startup, it drops and recreates `team_stats` and `match_results`.

```sh
python3 -m venv .
source bin/activate
pip install -r requirements.txt
cp .env.example .env
# fill in TBA_KEY and NEON_CONN_STR
python opr.py <event_key>
```
