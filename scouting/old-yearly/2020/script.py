''' Made by Michael Kaatz. '''
'''    Copyright 2020      '''

# Original script by Karan Arora

##################################  FOR NIKHIL AND TEJAS TO EDIT  ###########################################

''' Enter match key and what you want the file name to be. 
    It's not my problem if it doesn't work '''

event_key = "2020miket"
file_name = "Test_InfiniteRecharge"

''' READ: If using Chrome put Chrome/72.0.3626.109 instead of Mozilla/5.0 between the quotes next to user-agent.
    Not sure if this really matters but do it just in case. Now that I think about it this really shouldn't matter
    at all but whatever. '''

headers = {"X-TBA-Auth-Key": "4lrD467ePfemtjf19Wga60f2xKg0yDn4qVvDjLByw12EbwQ8jDgJhO5zFX1m7qgG",
           "User-agent": "Mozilla/5.0"}

############################################################################################################

import xlwt
import requests

url = "https://www.thebluealliance.com/api/v3/"

# Get data
r = requests.get("https://www.thebluealliance.com/api/v3/event/" + event_key + "/matches", headers=headers).json()

# Create spreadsheet and add red and blue sheets
file = xlwt.Workbook()
red = file.add_sheet("Red Alliance")
blue = file.add_sheet("Blue Alliance")

sheets = (red, blue)
teams = ("red", "blue")

video_message = ""
raw_data_message = ""

columns = {"record#": 0, "teams": 1, "starting_level": 2, "sstorm_action": 3, "bonus": 4, "sstorm_total": 5, "cargo": 6,
           "panels": 7, "comp_NR": 8, "comp_FR": 9, "hatch_pts": 10, "cargo_pts": 11, "endgame": 12, "hab_pts": 13,
           "teleop_pts": 14, "adjust_pts": 15, "comp_R_RP": 16, "hab_rp": 17, "foul_count": 18, "tech_foul_count": 19,
           "foul_pts": 20, "total_pts": 21, "winner": 22, "total_rp": 23, "match#": 24, "efficiency": 25}

# List of necessary headings - labels is not used for anything
labels = ("General", "Sandstorm", "Teleop", "Endgame/Totals", "Fouls", "Final Stats", "Fix Later")

labels2 = ("Record #", "Robots", "Starting Spot", "SStorm Action",

           "Bonus Points", "Total Auto Pts",

           "Total Cargo", "Total Panels",
                          
           # N = Near, F = Far
           "N Rocket Complete", "F Rocket Complete",

           "Hatch Points", "Cargo Points", "Endgame Action", "Total HAB Points",
           "Total Teleop Points", "Adjust Points",

           "Completed Rocket RP", "HAB RP",

           "Foul Count", "Tech Foul Count", "Foul Points Earned",

           "Total Points", "Win/Lose", "Total RP",
           
           "Match #", "Efficiency")

# Add labels in first row
for s in sheets:
    s.write(0, columns["record#"], "General")
    s.write(0, columns["starting_level"], "Sandstorm")
    s.write(0, columns["cargo"], "Teleop")
    s.write(0, columns["endgame"], "Endgame/Totals")
    s.write(0, columns["foul_count"], "Fouls")
    s.write(0, columns["total_pts"], "Final Stats")
    s.write(0, columns["match#"], "Fix Later")

# Add match numbers
row = 0

for match in range(len(r)):
    for s in sheets:
        s.write(row + 2, columns["record#"], match + 1)
    row += 3

# Add labels in second row
for l in range(len(labels2)):
    for s in sheets:
        s.write(1, l, labels2[l])

# Fill in data
current_row = 2

cargo = 0
panels = 0
cargo_list = []

for match in range(len(r)):
    try:
        for team in range(2):
            sheet = sheets[team]

            # Add team numbers
            for team_key in range(3):
                data = r[match]["alliances"][teams[team]]["team_keys"][team_key]
                sheet.write(current_row + team_key, columns["teams"], int(data.replace("frc", "")))

            data = r[match]["score_breakdown"][teams[team]]