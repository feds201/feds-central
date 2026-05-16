import time
import tbapy
import numpy as np
import psycopg2
from psycopg2.extras import execute_values
import os
from dotenv import load_dotenv

# --- CONFIGURATION ---
load_dotenv()
TBA_KEY = os.getenv("TBA_KEY")
NEON_CONN_STR = os.getenv("NEON_CONN_STR")

tba = tbapy.TBA(TBA_KEY)
event_key = '2026mil'

METRIC_MAP = {
    'opr':              'totalPoints',
    'hub_auto_fuel':    'autoCount',
    'hub_teleop_fuel':  'teleopCount',
    'hub_endgame_fuel': 'endgameCount',
    'auto_tower':       'autoTowerPoints',
    'total_tower':      'totalTowerPoints'
}

def get_deep_value(data, target_key):
    if isinstance(data, dict):
        if target_key in data: return data[target_key]
        for v in data.values():
            res = get_deep_value(v, target_key)
            if res is not None: return res
    elif isinstance(data, list):
        for item in data:
            res = get_deep_value(item, target_key)
            if res is not None: return res
    return None

def init_db():
    conn = psycopg2.connect(NEON_CONN_STR)
    cur = conn.cursor()

    # Existing team_stats table
    cur.execute("DROP TABLE IF EXISTS team_stats")
    cols = [
        "team_key TEXT PRIMARY KEY",
        "last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP",
        "opr FLOAT DEFAULT 0",
        "hub_auto_fuel_opr FLOAT DEFAULT 0",
        "hub_teleop_fuel_opr FLOAT DEFAULT 0",
        "hub_endgame_fuel_opr FLOAT DEFAULT 0",
        "hub_total_fuel_opr FLOAT DEFAULT 0",
        "auto_tower_opr FLOAT DEFAULT 0",
        "total_tower_opr FLOAT DEFAULT 0"
    ]
    cur.execute(f"CREATE TABLE team_stats ({', '.join(cols)})")

    # Match results table (match_number as INT)
    cur.execute("DROP TABLE IF EXISTS match_results")
    cur.execute("""
        CREATE TABLE match_results (
            match_number INT PRIMARY KEY,
            red_score INT,
            blue_score INT
        )
    """)

    conn.commit()
    cur.close()
    conn.close()
    print("Database Initialized.")

def sync_tba_scores(scored_matches):
    conn = psycopg2.connect(NEON_CONN_STR)
    cur = conn.cursor()
    values = []
    for m in scored_matches:
        values.append((
            int(m['match_number']), # Force to integer
            int(m['alliances']['red']['score']),
            int(m['alliances']['blue']['score'])
        ))

    query = """
        INSERT INTO match_results (match_number, red_score, blue_score)
        VALUES %s ON CONFLICT (match_number) DO UPDATE SET
        red_score = EXCLUDED.red_score, blue_score = EXCLUDED.blue_score
    """
    execute_values(cur, query, values)
    conn.commit()
    cur.close()
    conn.close()

def calculate_copr(team_keys, matches, api_key):
    team_list = sorted(team_keys)
    team_to_idx = {team: i for i, team in enumerate(team_list)}
    n = len(team_list)
    A = np.zeros((len(matches) * 2, n))
    b = np.zeros(len(matches) * 2)

    for i, m in enumerate(matches):
        for alliance in ['red', 'blue']:
            idx = i * 2 + (0 if alliance == 'red' else 1)
            for t_key in m['alliances'][alliance]['team_keys']:
                if t_key in team_to_idx:
                    A[idx, team_to_idx[t_key]] = 1
            val = get_deep_value(m['score_breakdown'][alliance], api_key)
            b[idx] = float(val) if val is not None else 0

    x, _, _, _ = np.linalg.lstsq(A, b, rcond=None)
    return {team: float(val) for team, val in zip(team_list, x)}

def update_neon(all_stats):
    conn = psycopg2.connect(NEON_CONN_STR)
    cur = conn.cursor()
    columns = ["team_key", "opr", "hub_auto_fuel_opr", "hub_teleop_fuel_opr",
               "hub_endgame_fuel_opr", "hub_total_fuel_opr", "auto_tower_opr", "total_tower_opr"]
    values = []
    for team, stats in all_stats.items():
        auto_f, tele_f, end_f = stats.get('autoCount', 0), stats.get('teleopCount', 0), stats.get('endgameCount', 0)
        values.append((team, stats.get('totalPoints', 0), auto_f, tele_f, end_f, (auto_f + tele_f + end_f),
                       stats.get('autoTowerPoints', 0), stats.get('totalTowerPoints', 0)))

    query = f"INSERT INTO team_stats ({', '.join(columns)}) VALUES %s ON CONFLICT (team_key) DO UPDATE SET " \
            f"{', '.join([f'{c} = EXCLUDED.{c}' for c in columns[1:]])}, last_updated = CURRENT_TIMESTAMP"
    execute_values(cur, query, values)
    conn.commit()
    cur.close()
    conn.close()

# --- MAIN LOOP ---
last_count = 0
db_initialized = False

while True:
    try:
        matches = tba.event_matches(event_key)
        scored_quals = [m for m in matches if m['comp_level'] == 'qm' and m.get('score_breakdown')]

        if scored_quals:
            if not db_initialized:
                init_db()
                db_initialized = True

            if len(scored_quals) > last_count:
                print(f"[{time.strftime('%H:%M:%S')}] Syncing {len(scored_quals)} match scores...")
                sync_tba_scores(scored_quals)

                team_keys = tba.event_teams(event_key, keys=True)
                team_results = {team: {} for team in team_keys}
                for label, api_key in METRIC_MAP.items():
                    coprs = calculate_copr(team_keys, scored_quals, api_key)
                    for team, val in coprs.items():
                        team_results[team][api_key] = val

                update_neon(team_results)
                last_count = len(scored_quals)
                print("Update complete.")
        else:
            print(f"Waiting for match data...")

    except Exception as e:
        print(f"Error: {e}")

    time.sleep(60)
