import json
import adit

event_data_summary = adit.StatboticsClient()

with open("event_teams.json", "w") as f:
    teams = event_data_summary.fetch_teams("2025miket")
    f.write(json.dumps(teams, indent=4))