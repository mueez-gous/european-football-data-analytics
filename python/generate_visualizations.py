"""
European Football Analytics - Visualization Generator
------------------------------------------------------
Connects to the SQLite European Soccer Database and generates publication-grade
visualizations for the GitHub repository documentation and analysis reports.

Generated Visualizations:
1. Match Result Distribution (Home Win vs Away Win vs Draw)
2. Home Advantage Percentage across 11 European Leagues
3. Goal Scoring Trajectory across 8 Seasons (2008/09 to 2015/16)
4. Top 10 Teams by Home Win Percentage (min 50 home matches)
5. Average Goals per Match by League
6. Player Technical & Physical Attributes Correlation Heatmap

Author: Mohammed Mueez Gous
Technologies: Python, SQLite3, Pandas, Matplotlib, Seaborn
"""

import os
import sqlite3
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

# Path configuration
BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
IMAGE_DIR = os.path.join(BASE_DIR, "images")
os.makedirs(IMAGE_DIR, exist_ok=True)

# Database search locations
POSSIBLE_DB_PATHS = [
    os.path.join(BASE_DIR, "database.sqlite"),
    r"C:\Users\Admin\Desktop\football-analysis\database.sqlite\database.sqlite",
    r"C:\Users\Admin\Desktop\football-analysis\database.sqlite",
]
DB_PATH = next((p for p in POSSIBLE_DB_PATHS if os.path.exists(p) and os.path.isfile(p)), POSSIBLE_DB_PATHS[1])

# Visual style configuration
plt.style.use("seaborn-v0_8-whitegrid" if "seaborn-v0_8-whitegrid" in plt.style.available else "default")
plt.rcParams["font.family"] = "sans-serif"
plt.rcParams["font.size"] = 11


def generate_all_charts():
    print(f"Connecting to European Soccer Database: {DB_PATH}")
    conn = sqlite3.connect(DB_PATH)

    # -------------------------------------------------------------------------
    # 1. Match Result Distribution (Home Win vs Away Win vs Draw)
    # -------------------------------------------------------------------------
    print("[1/6] Generating Match Result Distribution Chart...")
    q1 = """
    SELECT 
        CASE 
            WHEN home_team_goal > away_team_goal THEN 'Home Win'
            WHEN home_team_goal < away_team_goal THEN 'Away Win'
            ELSE 'Draw' 
        END AS result,
        COUNT(*) AS count
    FROM Match
    GROUP BY result
    ORDER BY count DESC;
    """
    df_results = pd.read_sql(q1, conn)
    total_matches = df_results["count"].sum()

    fig, ax = plt.subplots(figsize=(8, 5))
    colors = ["#10b981", "#ef4444", "#64748b"]  # Green for home, red for away, slate for draw
    bars = ax.bar(df_results["result"], df_results["count"], color=colors, edgecolor="#1e293b", linewidth=1.2)
    ax.set_title("Match Results Distribution (25,979 Matches | 2008-2016)", fontsize=13, fontweight="bold", pad=12)
    ax.set_ylabel("Number of Matches", fontweight="bold")
    ax.set_xlabel("Match Outcome", fontweight="bold")
    ax.grid(axis="y", linestyle="--", alpha=0.5)

    for bar in bars:
        h = bar.get_height()
        pct = (h / total_matches) * 100
        ax.annotate(f"{h:,}\n({pct:.1f}%)", (bar.get_x() + bar.get_width() / 2, h / 2),
                    ha="center", va="center", color="white", fontweight="bold", fontsize=11)

    plt.tight_layout()
    p1 = os.path.join(IMAGE_DIR, "01_match_results_distribution.png")
    plt.savefig(p1, dpi=300)
    plt.close()
    print(f"      Saved: {p1}")

    # -------------------------------------------------------------------------
    # 2. Home Win Percentage by League
    # -------------------------------------------------------------------------
    print("[2/6] Generating Home Advantage by League Chart...")
    q2 = """
    SELECT 
        l.name AS league,
        COUNT(*) AS total_matches,
        SUM(CASE WHEN m.home_team_goal > m.away_team_goal THEN 1 ELSE 0 END) AS home_wins,
        ROUND(100.0 * SUM(CASE WHEN m.home_team_goal > m.away_team_goal THEN 1 ELSE 0 END) / COUNT(*), 1) AS home_win_pct
    FROM Match m
    JOIN League l ON m.league_id = l.id
    GROUP BY l.name
    ORDER BY home_win_pct ASC;
    """
    df_league = pd.read_sql(q2, conn)

    fig, ax = plt.subplots(figsize=(10, 6))
    bars = ax.barh(df_league["league"], df_league["home_win_pct"], color="#3b82f6", edgecolor="#1d4ed8")
    ax.set_title("Home Advantage: Home Win % across European Leagues", fontsize=13, fontweight="bold", pad=12)
    ax.set_xlabel("Home Win Percentage (%)", fontweight="bold")
    ax.axvline(x=45.87, color="#dc2626", linestyle="--", linewidth=1.5, label="Overall Average (45.9%)")
    ax.legend(loc="lower right")
    ax.grid(axis="x", linestyle="--", alpha=0.5)

    for bar in bars:
        w = bar.get_width()
        ax.annotate(f"{w:.1f}%", (w - 3.5, bar.get_y() + bar.get_height() / 2),
                    ha="center", va="center", color="white", fontweight="bold", fontsize=10)

    plt.tight_layout()
    p2 = os.path.join(IMAGE_DIR, "02_home_win_by_league.png")
    plt.savefig(p2, dpi=300)
    plt.close()
    print(f"      Saved: {p2}")

    # -------------------------------------------------------------------------
    # 3. Goal Scoring Trajectory Across 8 Seasons
    # -------------------------------------------------------------------------
    print("[3/6] Generating Goal Trends Across 8 Seasons Chart...")
    q3 = """
    SELECT 
        season,
        CAST(SUBSTR(season, 1, 4) AS INT) AS season_start_year,
        COUNT(*) AS total_matches,
        SUM(home_team_goal + away_team_goal) AS total_goals,
        ROUND(AVG(home_team_goal + away_team_goal), 2) AS avg_goals_per_match
    FROM Match
    GROUP BY season
    ORDER BY season_start_year ASC;
    """
    df_seasons = pd.read_sql(q3, conn)

    fig, ax = plt.subplots(figsize=(10, 5))
    ax.plot(df_seasons["season"], df_seasons["avg_goals_per_match"], marker="o", color="#d97706", linewidth=2.8, markersize=8)
    ax.set_title("Average Goals Scored per Match by Season (2008/09 to 2015/16)", fontsize=13, fontweight="bold", pad=12)
    ax.set_xlabel("European Season", fontweight="bold")
    ax.set_ylabel("Goals per Match", fontweight="bold")
    ax.set_ylim(2.5, 2.9)
    ax.grid(True, linestyle="--", alpha=0.5)

    for i, row in df_seasons.iterrows():
        ax.annotate(f"{row['avg_goals_per_match']:.2f}", (row["season"], row["avg_goals_per_match"] + 0.02),
                    ha="center", fontweight="bold", fontsize=10)

    plt.tight_layout()
    p3 = os.path.join(IMAGE_DIR, "03_goals_per_match_by_season.png")
    plt.savefig(p3, dpi=300)
    plt.close()
    print(f"      Saved: {p3}")

    # -------------------------------------------------------------------------
    # 4. Top 10 Teams by Home Win Percentage
    # -------------------------------------------------------------------------
    print("[4/6] Generating Top Home Dominance Teams Chart...")
    q4 = """
    SELECT 
        home.team_long_name AS team,
        COUNT(*) AS total_home_matches,
        SUM(CASE WHEN m.home_team_goal > m.away_team_goal THEN 1 ELSE 0 END) AS home_wins,
        ROUND(100.0 * SUM(CASE WHEN m.home_team_goal > m.away_team_goal THEN 1 ELSE 0 END) / COUNT(*), 1) AS home_win_pct
    FROM Match m
    JOIN Team home ON m.home_team_api_id = home.team_api_id
    GROUP BY home.team_long_name
    HAVING total_home_matches >= 50
    ORDER BY home_win_pct ASC
    LIMIT 10;
    """
    df_top_teams = pd.read_sql(q4, conn)

    # Let's get the top 10 descending then reverse for clean horizontal bar chart
    q4_desc = """
    SELECT 
        home.team_long_name AS team,
        COUNT(*) AS total_home_matches,
        SUM(CASE WHEN m.home_team_goal > m.away_team_goal THEN 1 ELSE 0 END) AS home_wins,
        ROUND(100.0 * SUM(CASE WHEN m.home_team_goal > m.away_team_goal THEN 1 ELSE 0 END) / COUNT(*), 1) AS home_win_pct
    FROM Match m
    JOIN Team home ON m.home_team_api_id = home.team_api_id
    GROUP BY home.team_long_name
    HAVING total_home_matches >= 50
    ORDER BY home_win_pct DESC
    LIMIT 10;
    """
    df_top10 = pd.read_sql(q4_desc, conn).iloc[::-1]

    fig, ax = plt.subplots(figsize=(10, 6))
    bars = ax.barh(df_top10["team"], df_top10["home_win_pct"], color="#8b5cf6", edgecolor="#6d28d9")
    ax.set_title("Top 10 European Teams by Home Win % (Min. 50 Home Matches)", fontsize=13, fontweight="bold", pad=12)
    ax.set_xlabel("Home Win %", fontweight="bold")
    ax.grid(axis="x", linestyle="--", alpha=0.5)

    for bar in bars:
        w = bar.get_width()
        ax.annotate(f"{w:.1f}%", (w - 4.5, bar.get_y() + bar.get_height() / 2),
                    ha="center", va="center", color="white", fontweight="bold", fontsize=10)

    plt.tight_layout()
    p4 = os.path.join(IMAGE_DIR, "04_top_home_teams.png")
    plt.savefig(p4, dpi=300)
    plt.close()
    print(f"      Saved: {p4}")

    # -------------------------------------------------------------------------
    # 5. Average Goals per Match by League
    # -------------------------------------------------------------------------
    print("[5/6] Generating Average Goals per Match by League Chart...")
    q5 = """
    SELECT 
        l.name AS league,
        SUM(m.home_team_goal + m.away_team_goal) AS total_goals,
        ROUND(AVG(m.home_team_goal + m.away_team_goal), 2) AS avg_goals_per_match
    FROM Match m
    JOIN League l ON m.league_id = l.id
    GROUP BY l.name
    ORDER BY avg_goals_per_match ASC;
    """
    df_goals_league = pd.read_sql(q5, conn)

    fig, ax = plt.subplots(figsize=(10, 6))
    bars = ax.barh(df_goals_league["league"], df_goals_league["avg_goals_per_match"], color="#059669", edgecolor="#047857")
    ax.set_title("Average Goals per Match across European Leagues", fontsize=13, fontweight="bold", pad=12)
    ax.set_xlabel("Average Goals per Match", fontweight="bold")
    ax.grid(axis="x", linestyle="--", alpha=0.5)

    for bar in bars:
        w = bar.get_width()
        ax.annotate(f"{w:.2f}", (w - 0.2, bar.get_y() + bar.get_height() / 2),
                    ha="center", va="center", color="white", fontweight="bold", fontsize=10)

    plt.tight_layout()
    p5 = os.path.join(IMAGE_DIR, "05_avg_goals_by_league.png")
    plt.savefig(p5, dpi=300)
    plt.close()
    print(f"      Saved: {p5}")

    # -------------------------------------------------------------------------
    # 6. Correlation Heatmap of Player Attributes
    # -------------------------------------------------------------------------
    print("[6/6] Generating Player Attributes Correlation Matrix...")
    q6 = """
    SELECT overall_rating, crossing, finishing, heading_accuracy, short_passing,
           dribbling, ball_control, acceleration, sprint_speed, shot_power,
           stamina, strength, long_shots, aggression, marking, standing_tackle
    FROM Player_Attributes
    WHERE overall_rating IS NOT NULL;
    """
    df_attr = pd.read_sql(q6, conn)
    corr = df_attr.corr()

    fig, ax = plt.subplots(figsize=(12, 9))
    sns.heatmap(corr, annot=True, fmt=".2f", cmap="Blues", cbar=True, ax=ax, annot_kws={"size": 8})
    ax.set_title("Player Technical & Physical Attributes Correlation Matrix", fontsize=14, fontweight="bold", pad=12)
    plt.tight_layout()
    p6 = os.path.join(IMAGE_DIR, "06_player_attributes_correlation.png")
    plt.savefig(p6, dpi=300)
    plt.close()
    print(f"      Saved: {p6}")

    conn.close()
    print("\nSUCCESS: All 6 visualization charts generated successfully!")


if __name__ == "__main__":
    generate_all_charts()
