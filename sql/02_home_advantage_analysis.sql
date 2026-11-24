-- ============================================================================
-- Project: European Football Data Analytics Platform
-- File: 02_home_advantage_analysis.sql
-- Description: Empirical Analysis of Home Pitch Advantage across 25,979 Matches
-- ============================================================================

-- ----------------------------------------------------------------------------
-- QUERY 1: Macro Match Outcome Distribution (2008 to 2016)
-- Quantifies the fundamental distribution of match outcomes.
-- Expected Result:
--   Home Win : 11,917 matches (45.87%)
--   Away Win : 7,466 matches (28.74%)
--   Draw     : 6,596 matches (25.39%)
-- Demonstrates teams win 1.6x more matches at home than away.
-- ----------------------------------------------------------------------------
SELECT 
    CASE 
        WHEN home_team_goal > away_team_goal THEN 'Home Win'
        WHEN home_team_goal < away_team_goal THEN 'Away Win'
        ELSE 'Draw' 
    END AS match_result,
    COUNT(*) AS total_matches,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM Match), 2) AS percentage_of_total
FROM Match
GROUP BY match_result
ORDER BY total_matches DESC;


-- ----------------------------------------------------------------------------
-- QUERY 2: League-by-League Home Advantage Ranking
-- Ranks all 11 European leagues by home win percentage.
-- Highlights leagues where home advantage is most pronounced (Spain leads at 48.8%).
-- ----------------------------------------------------------------------------
SELECT 
    l.name AS league_name,
    c.name AS country,
    COUNT(m.id) AS total_matches,
    SUM(CASE WHEN m.home_team_goal > m.away_team_goal THEN 1 ELSE 0 END) AS home_wins,
    SUM(CASE WHEN m.home_team_goal < m.away_team_goal THEN 1 ELSE 0 END) AS away_wins,
    SUM(CASE WHEN m.home_team_goal = m.away_team_goal THEN 1 ELSE 0 END) AS draws,
    ROUND(100.0 * SUM(CASE WHEN m.home_team_goal > m.away_team_goal THEN 1 ELSE 0 END) / COUNT(m.id), 2) AS home_win_pct,
    ROUND(100.0 * SUM(CASE WHEN m.home_team_goal < m.away_team_goal THEN 1 ELSE 0 END) / COUNT(m.id), 2) AS away_win_pct
FROM Match m
JOIN League l ON m.league_id = l.id
JOIN Country c ON l.country_id = c.id
GROUP BY l.name, c.name
ORDER BY home_win_pct DESC;


-- ----------------------------------------------------------------------------
-- QUERY 3: Home vs Away Goal Scoring Differential
-- Analyzes whether home advantage stems from superior attacking output or defensive solidity.
-- ----------------------------------------------------------------------------
SELECT 
    l.name AS league_name,
    ROUND(AVG(m.home_team_goal), 2) AS avg_home_goals,
    ROUND(AVG(m.away_team_goal), 2) AS avg_away_goals,
    ROUND(AVG(m.home_team_goal) - AVG(m.away_team_goal), 2) AS goal_advantage_margin,
    ROUND(1.0 * SUM(m.home_team_goal) / SUM(m.away_team_goal), 2) AS home_to_away_goal_ratio
FROM Match m
JOIN League l ON m.league_id = l.id
GROUP BY l.name
ORDER BY goal_advantage_margin DESC;


-- ----------------------------------------------------------------------------
-- QUERY 4: Top 20 Most Dominant European Teams at Home
-- Identifies European clubs with the highest fortress factor (min. 50 home games).
-- ----------------------------------------------------------------------------
SELECT 
    t.team_long_name AS team,
    l.name AS league,
    COUNT(m.id) AS home_matches_played,
    SUM(CASE WHEN m.home_team_goal > m.away_team_goal THEN 1 ELSE 0 END) AS home_victories,
    SUM(CASE WHEN m.home_team_goal = m.away_team_goal THEN 1 ELSE 0 END) AS home_draws,
    SUM(CASE WHEN m.home_team_goal < m.away_team_goal THEN 1 ELSE 0 END) AS home_defeats,
    SUM(m.home_team_goal) AS goals_scored_at_home,
    SUM(m.away_team_goal) AS goals_conceded_at_home,
    ROUND(100.0 * SUM(CASE WHEN m.home_team_goal > m.away_team_goal THEN 1 ELSE 0 END) / COUNT(m.id), 1) AS home_win_pct
FROM Match m
JOIN Team t ON m.home_team_api_id = t.team_api_id
JOIN League l ON m.league_id = l.id
GROUP BY t.team_long_name, l.name
HAVING home_matches_played >= 50
ORDER BY home_win_pct DESC
LIMIT 20;


-- ----------------------------------------------------------------------------
-- QUERY 5: Home Advantage Resilience Over Time
-- Checks whether home advantage has increased, decreased, or remained static across the 8 seasons.
-- ----------------------------------------------------------------------------
SELECT 
    season,
    COUNT(*) AS total_matches,
    SUM(CASE WHEN home_team_goal > away_team_goal THEN 1 ELSE 0 END) AS home_wins,
    ROUND(100.0 * SUM(CASE WHEN home_team_goal > away_team_goal THEN 1 ELSE 0 END) / COUNT(*), 2) AS home_win_pct,
    ROUND(AVG(home_team_goal), 2) AS avg_home_goals,
    ROUND(AVG(away_team_goal), 2) AS avg_away_goals
FROM Match
GROUP BY season
ORDER BY season ASC;
