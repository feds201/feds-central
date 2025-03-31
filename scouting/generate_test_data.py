import csv
import random
from faker import Faker

fake = Faker()
output_file = r"c:\Users\rites\AppData\Local\ScoutOps\generated_results.csv"
num_teams, matches_per_team = 40, 8
num_matches = (num_teams * matches_per_team) // 6

columns = [
    "teamNumber", "scouterName", "matchKey", "allianceColor", "eventKey", "station", "matchNumber",
    "auton_CoralScoringLevel1", "auton_CoralScoringLevel2", "auton_CoralScoringLevel3", "auton_CoralScoringLevel4",
    "auton_LeftBarge", "auton_AlgaeScoringProcessor", "auton_AlgaeScoringBarge", "botLocation",
    "teleop_CoralScoringLevel1", "teleop_CoralScoringLevel2", "teleop_CoralScoringLevel3", "teleop_CoralScoringLevel4",
    "teleop_AlgaeScoringBarge", "teleop_AlgaeScoringProcessor", "teleop_AlgaePickUp", "teleop_Defense",
    "endgame_Deep_Climb", "endgame_Shallow_Climb", "endgame_Park", "endgame_Comments"
]

def generate_data():
    teams = random.sample(range(1000, 9999), num_teams)
    team_matches = {team: 0 for team in teams}
    data = []

    for match in range(1, num_matches + 1):
        match_key = f"2025mitry_qm{match}"
        for alliance_color in ["Red", "Blue"]:
            for station in range(1, 4):
                team = random.choice([t for t in teams if team_matches[t] < matches_per_team])
                team_matches[team] += 1
                row = [
                    team, fake.name(), match_key, alliance_color, "2025mitry", station, match,
                    *[random.randint(0, 5) for _ in range(4)], random.choice([True, False]),
                    random.randint(0, 3), random.randint(0, 2), "null",
                    *[random.randint(0, 10) for _ in range(4)], random.randint(0, 5), random.randint(0, 5),
                    random.randint(0, 10), random.choice([True, False]),
                    random.choice([True, False]), random.choice([True, False]), random.choice([True, False]),
                    fake.sentence() if random.random() > 0.8 else ""
                ]
                data.append(row)
    return data

def write_csv(file_path, data):
    with open(file_path, "w", newline="") as file:
        writer = csv.writer(file)
        writer.writerow(columns)
        writer.writerows(data)

def main():
    print("Generating test data...")
    data = generate_data()
    write_csv(output_file, data)
    print(f"Data saved to {output_file}")

if __name__ == "__main__":
    main()
