-- ============================================================================
-- Project: European Football Data Analytics Platform
-- File: 03_goal_scoring_trends.sql
-- Description: Longitudinal Goal Scoring Evolution & Match Excitement Analytics
-- ============================================================================

-- ----------------------------------------------------------------------------
-- QUERY 1: Goal Scoring Trajectory Across 8 Seasons (2008/09 to 2015/16)
-- Measures changes in offensive production across European football.
-- Demonstrates an increase from 2.61 to 2.77 goals per match.
-- ----------------------------------------------------------------------------
SELECT 
    season,
    CAST(SUBSTR(season, 1, 4) AS INT) AS start_year,
    COUNT(*) AS total_matches,
    SUM(home_team_goal + away_team_goal) AS total_goals_scored,
    ROUND(AVG(home_team_goal + away_team_goal), 2) AS avg_goals_per_match,
    SUM(home_team_goal) AS total_home_goals,
    SUM(away_team_goal) AS total_away_goals
FROM Match
GROUP BY season
ORDER BY start_year ASC;


-- ----------------------------------------------------------------------------
-- QUERY 2: League Scoring Hierarchy
-- Compares offensive output across all 11 European leagues.
-- Highlights high-scoring leagues (Switzerland, Germany, Netherlands).
-- ----------------------------------------------------------------------------
SELECT 
    l.name AS league_name,
    COUNT(m.id) AS total_matches,
    SUM(m.home_team_goal + m.away_team_goal) AS total_goals,
    ROUND(AVG(m.home_team_goal + m.away_team_goal), 2) AS avg_goals_per_match,
    ROUND(AVG(m.home_team_goal), 2) AS avg_home_goals,
    ROUND(AVG(m.away_team_goal), 2) AS avg_away_goals
FROM Match m
JOIN League l ON m.league_id = l.id
GROUP BY l.name
ORDER BY avg_goals_per_match DESC;


-- ----------------------------------------------------------------------------
-- QUERY 3: High-Scoring Thrillers (Matches with 7+ Total Goals)
-- Identifies the most dramatic, offensive fixtures in European history.
-- ----------------------------------------------------------------------------
SELECT 
    m.date,
    m.season,
    l.name AS league,
    home.team_long_name AS home_team,
    m.home_team_goal,
    away.team_long_name AS away_team,
    m.away_team_goal,
    (m.home_team_goal + m.away_team_goal) AS total_goals
FROM Match m
JOIN League l ON m.league_id = l.id
JOIN Team home ON m.home_team_api_id = home.team_api_id
JOIN Team away ON m.away_team_api_id = away.team_api_id
WHERE (m.home_team_goal + m.away_team_goal) >= 7
ORDER BY total_goals DESC, m.date DESC
LIMIT 15;


-- ----------------------------------------------------------------------------
-- QUERY 4: Lopsided Match Blowouts (Goal Difference >= 6)
-- Flags fixtures characterized by complete tactical domination.
-- ----------------------------------------------------------------------------
SELECT 
    m.date,
    m.season,
    l.name AS league,
    home.team_long_name AS home_team,
    m.home_team_goal,
    away.team_long_name AS away_team,
    m.away_team_goal,
    ABS(m.home_team_goal - m.away_team_goal) AS goal_difference,
    CASE 
        WHEN m.home_team_goal > m.away_team_goal THEN home.team_long_name
        ELSE away.team_long_name 
    END AS victorious_team
FROM Match m
JOIN League l ON m.league_id = l.id
JOIN Team home ON m.home_team_api_id = home.team_api_id
JOIN Team away ON m.away_team_api_id = away.team_api_id
WHERE ABS(m.home_team_goal - m.away_team_goal) >= 6
ORDER BY goal_difference DESC, m.date DESC
LIMIT 15;


-- ----------------------------------------------------------------------------
-- QUERY 5: Clean Sheet & Defensive Resilience by League
-- Calculates the proportion of matches where at least one team kept a clean sheet.
-- ----------------------------------------------------------------------------
SELECT 
    l.name AS league_name,
    COUNT(m.id) AS total_matches,
    SUM(CASE WHEN m.away_team_goal = 0 THEN 1 ELSE 0 END) AS home_clean_sheets,
    SUM(CASE WHEN m.home_team_goal = 0 THEN 1 ELSE 0 END) AS away_clean_sheets,
    ROUND(100.0 * (SUM(CASE WHEN m.away_team_goal = 0 THEN 1 ELSE 0 END) + 
                   SUM(CASE WHEN m.home_team_goal = 0 THEN 1 ELSE 0 END)) / (2.0 * COUNT(m.id)), 2) AS clean_sheet_rate_pct
FROM Match m
JOIN League l ON m.league_id = l.id
GROUP BY l.name
ORDER BY clean_sheet_rate_pct DESC;
