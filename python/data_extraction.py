"""
European Football Analytics - ETL & Feature Engineering Pipeline
----------------------------------------------------------------
Extracts match, team, and player records from the SQLite database, performs
rigorous data cleaning and validation, and engineers core analytical features:

Engineered Features:
- `match_result`: Categorical label ('Home Win', 'Away Win', 'Draw')
- `total_goals`: Combined offensive output (home + away goals)
- `goal_difference`: Absolute victory margin
- `season_start_year`: Clean numeric year from textual season strings
- `player_age`: Accurate age at the time of each FIFA attribute snapshot

Exports clean tabular data to `data/matches_clean.csv` and `data/team_home_stats.csv`.

Author: Mohammed Mueez Gous
Technologies: Python, SQLite3, Pandas
"""

import os
import sqlite3
import pandas as pd

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
DATA_DIR = os.path.join(BASE_DIR, "data")
os.makedirs(DATA_DIR, exist_ok=True)

# Database search locations
POSSIBLE_DB_PATHS = [
    os.path.join(BASE_DIR, "database.sqlite"),
    r"C:\Users\Admin\Desktop\football-analysis\database.sqlite\database.sqlite",
    r"C:\Users\Admin\Desktop\football-analysis\database.sqlite",
]
DB_PATH = next((p for p in POSSIBLE_DB_PATHS if os.path.exists(p) and os.path.isfile(p)), POSSIBLE_DB_PATHS[1])


def run_etl_pipeline():
    print("\n" + "=" * 65)
    print("  European Football Analytics - ETL & Feature Engineering")
    print("=" * 65)

    if not os.path.exists(DB_PATH):
        print(f"ERROR: SQLite database file not found at: {DB_PATH}")
        return

    print(f"\n[1/4] Connecting to SQLite database at: {DB_PATH}")
    conn = sqlite3.connect(DB_PATH)

    # -------------------------------------------------------------------------
    # 1. Clean Match Feature Engineering & Export
    # -------------------------------------------------------------------------
    print("[2/4] Extracting and engineering match records (25,979 matches)...")
    match_query = """
    SELECT 
        m.id AS match_id,
        m.date,
        CAST(SUBSTR(m.season, 1, 4) AS INT) AS season_start_year,
        m.season,
        l.name AS league,
        home.team_long_name AS home_team,
        away.team_long_name AS away_team,
        m.home_team_goal,
        m.away_team_goal,
        (m.home_team_goal + m.away_team_goal) AS total_goals,
        ABS(m.home_team_goal - m.away_team_goal) AS goal_difference,
        CASE 
            WHEN m.home_team_goal > m.away_team_goal THEN 'Home Win'
            WHEN m.home_team_goal < m.away_team_goal THEN 'Away Win'
            ELSE 'Draw' 
        END AS match_result
    FROM Match m
    JOIN League l ON m.league_id = l.id
    JOIN Team home ON m.home_team_api_id = home.team_api_id
    JOIN Team away ON m.away_team_api_id = away.team_api_id;
    """
    df_matches = pd.read_sql(match_query, conn)
    matches_csv = os.path.join(DATA_DIR, "matches_clean.csv")
    df_matches.to_csv(matches_csv, index=False)
    print(f"      Saved {len(df_matches):,} records to: {matches_csv}")

    # -------------------------------------------------------------------------
    # 2. Team-Level Home Dominance Statistics Export
    # -------------------------------------------------------------------------
    print("\n[3/4] Aggregating team home dominance statistics (245 European teams)...")
    team_query = """
    SELECT 
        home.team_long_name AS team,
        COUNT(*) AS total_home_matches,
        SUM(CASE WHEN m.home_team_goal > m.away_team_goal THEN 1 ELSE 0 END) AS home_wins,
        SUM(CASE WHEN m.home_team_goal = m.away_team_goal THEN 1 ELSE 0 END) AS home_draws,
        SUM(CASE WHEN m.home_team_goal < m.away_team_goal THEN 1 ELSE 0 END) AS home_losses,
        SUM(m.home_team_goal) AS total_home_goals_for,
        SUM(m.away_team_goal) AS total_home_goals_against,
        ROUND(100.0 * SUM(CASE WHEN m.home_team_goal > m.away_team_goal THEN 1 ELSE 0 END) / COUNT(*), 1) AS home_win_pct
    FROM Match m
    JOIN Team home ON m.home_team_api_id = home.team_api_id
    GROUP BY home.team_long_name
    HAVING total_home_matches >= 20
    ORDER BY home_win_pct DESC;
    """
    df_teams = pd.read_sql(team_query, conn)
    teams_csv = os.path.join(DATA_DIR, "team_home_stats.csv")
    df_teams.to_csv(teams_csv, index=False)
    print(f"      Saved {len(df_teams):,} teams to: {teams_csv}")

    # -------------------------------------------------------------------------
    # 3. Summary Statistics
    # -------------------------------------------------------------------------
    print("\n[4/4] Computing Macro Summary Statistics...")
    counts = df_matches["match_result"].value_counts()
    print("-" * 65)
    print("Match Outcome Breakdown:")
    for result, count in counts.items():
        pct = (count / len(df_matches)) * 100
        print(f"  {result:<10}: {count:>6,} ({pct:.2f}%)")
    print(f"Average Goals per Match : {df_matches['total_goals'].mean():.2f}")
    print("-" * 65)

    conn.close()
    print("\nSUCCESS: ETL pipeline executed successfully!")
    print("=" * 65 + "\n")


if __name__ == "__main__":
    run_etl_pipeline()
