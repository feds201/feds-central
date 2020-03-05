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

columns = {"record#": 0, "teams": 1, "init_line": 2, "init_line_points": 3, "auton_bottom": 4, "auton_top": 5, "auton_inner": 6,
           "auton_cell": 7, "auton_total": 8, "teleop_bottom": 9, "teleop_top": 10, "teleop_inner": 11, "teleop_cell": 12,
		   "control_panel_color": 13, "control_panel": 14, "stage_activated": 15, "teleop_total": 16,
		   "endgame_state": 17, "endgame_shield_energized": 18, "endgame_shield_operational": 19, "endgame_shield_level": 20, "endgame_shield_foul": 21, "endgame_total": 22,
		   "foul_count": 23, "tech_foul_count": 24, "foul_pts": 25, "total_pts": 26, "winner": 27, "total_rp": 28, "match#": 29, "efficiency": 30}

# List of necessary headings - labels is not used for anything
labels = ("General", "Auton", "Teleop", "Endgame/Totals", "Fouls", "Final Stats", "Fix Later")

labels2 = ("Record #", "Robots", "Init Line", "Init Line Points",

           "Auton Cells Bottom", "Auton Cells Top", "Auton Cells Inner", "Auton Cells Total", "Auton Total",

           "Teleop Cells Bottom", "Teleop Cells Top", "Teleop Cells Inner", "Teleop Cells Total",
		   
		   "Control Panel Color", "Control Panel Points", "Stage Activated", "Teleop Total",
		   
		   "Endgame State", "Shield Energized", "Shield Operational", "Shield Level", "Shield Foul", "Endgame Total",
		   
		   "Foul Count", "Tech Foul Count", "Foul Points Earned",

           "Total Points", "Win/Lose", "Total RP",
           
           "Match #", "Efficiency")

# Add labels in first row
for s in sheets:
    s.write(0, columns["record#"], "General")
    s.write(0, columns["init_line"], "Auton")
    s.write(0, columns["teleop_bottom"], "Teleop")
    s.write(0, columns["endgame_state"], "Endgame/Totals")
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

for match in range(len(r)):
	try:
		for team in range(2):
			sheet = sheets[team]
			
			# Add team numbers
			for team_key in range(3):
				data = r[match]["alliances"][teams[team]]["team_keys"][team_key]
				sheet.write(current_row + team_key, columns["teams"], int(data.replace("frc", "")))
			
			data = r[match]["score_breakdown"][teams[team]]
			
			# Init line
			sheet.write(current_row, columns["init_line"], data["initLineRobot1"])
			sheet.write(current_row + 1, columns["init_line"], data["initLineRobot2"])
			sheet.write(current_row + 2, columns["init_line"], data["initLineRobot3"])
			
			sheet.write(current_row, columns["init_line_points"], data["autoInitLinePoints"])
			
			# Auton
			sheet.write(current_row, columns["auton_bottom"], data["autoCellsBottom"])
			sheet.write(current_row, columns["auton_top"], data["autoCellsOuter"])
			sheet.write(current_row, columns["auton_inner"], data["autoCellsInner"])
			sheet.write(current_row, columns["auton_cell"], data["autoCellPoints"])
			
			sheet.write(current_row, columns["auton_total"], data["autoPoints"])
			
			# Teleop
			sheet.write(current_row, columns["teleop_bottom"], data["teleopCellsBottom"])
			sheet.write(current_row, columns["teleop_top"], data["teleopCellsOuter"])
			sheet.write(current_row, columns["teleop_inner"], data["teleopCellsInner"])
			sheet.write(current_row, columns["teleop_cell"], data["teleopCellPoints"])
			
			sheet.write(current_row, columns["control_panel_color"], data["stage3TargetColor"])
			sheet.write(current_row, columns["control_panel"], data["controlPanelPoints"])
			
			sheet.write(current_row, columns["teleop_total"], data["teleopPoints"])
			
			if data["stage3Activated"]:
				sheet.write(current_row, columns["stage_activated"], "3")
			elif data["stage2Activated"]:
				sheet.write(current_row, columns["stage_activated"], "2")
			elif data["stage1Activated"]:
				sheet.write(current_row, columns["stage_activated"], "1")
			else:
				sheet.write(current_row, columns["stage_activated"], "0")
			
			# Endgame
			sheet.write(current_row, columns["endgame_state"], data["endgameRobot1"])
			sheet.write(current_row + 1, columns["endgame_state"], data["endgameRobot2"])
			sheet.write(current_row + 2, columns["endgame_state"], data["endgameRobot3"])
			
			sheet.write(current_row, columns["endgame_shield_energized"], data["shieldEnergizedRankingPoint"])
			sheet.write(current_row, columns["endgame_shield_operational"], data["shieldOperationalRankingPoint"])
			sheet.write(current_row, columns["endgame_shield_level"], data["endgameRungIsLevel"])
			sheet.write(current_row, columns["endgame_shield_foul"], data["tba_shieldEnergizedRankingPointFromFoul"])
			
			sheet.write(current_row, columns["endgame_total"], data["endgamePoints"])
			
			# Fouls
			sheet.write(current_row, columns["foul_count"], data["foulCount"])
			sheet.write(current_row, columns["tech_foul_count"], data["techFoulCount"])
			sheet.write(current_row, columns["foul_pts"], data["foulPoints"])

			# Total points
			sheet.write(current_row, columns["total_pts"], data["totalPoints"])

			# Win or lose (potential source for error due to if-else?)
			temp = str(r[match]["winning_alliance"])

			if temp == teams[team]:
				temp = "Win"
			else:
				temp = "Loss"

			sheet.write(current_row, columns["winner"], temp)

			# Total ranking points
			sheet.write(current_row, columns["total_rp"], data["rp"])
			
	except TypeError as e:
		print("Ends at Record " + str(match))
		print(e)
	
	current_row += 3
	
	# Add video to message
	video_message += str(match + 1) + ": "
	temp = r[match]["videos"]
	
	for video in temp:
		if video["type"] == "youtube":
			video_message += ("youtube.com/watch?v=" + str(video["key"]) + ", ")
		else:
			video_message(str(video["key"] + "(video type is " + video["type"] + ")" + ", "))
	
	video_message += "\n"

# Write raw data to file
try:
	raw_data_file = open("rawdata.json", "w")

	for entry in r:
		raw_data_file.write(str(entry))
		raw_data_file.write("\n \n")

	raw_data_file.close()

except IOError as e:
	print("WARNING: IOError in writing raw data to file")
	print(e)

file.save(file_name + ".xls")