-- ============================================================================
-- Project: European Football Data Analytics Platform
-- File: 04_player_scouting_queries.sql
-- Description: Player Performance, Scouting, and Attribute Correlation Queries
-- ============================================================================

-- ----------------------------------------------------------------------------
-- QUERY 1: Top 25 Highest-Rated Players in European History
-- Uses window functions to deduplicate periodic snapshots to the latest evaluation.
-- ----------------------------------------------------------------------------
WITH latest_player_evaluations AS (
    SELECT 
        pa.player_api_id,
        p.player_name,
        p.birthday,
        pa.date AS evaluation_date,
        pa.overall_rating,
        pa.potential,
        pa.preferred_foot,
        ROW_NUMBER() OVER (PARTITION BY pa.player_api_id ORDER BY pa.date DESC) AS rn
    FROM Player_Attributes pa
    JOIN Player p ON pa.player_api_id = p.player_api_id
    WHERE pa.overall_rating IS NOT NULL
)
SELECT 
    player_name,
    overall_rating,
    potential,
    preferred_foot,
    evaluation_date,
    ROUND((JULIANDAY(evaluation_date) - JULIANDAY(birthday)) / 365.25, 1) AS age_at_evaluation
FROM latest_player_evaluations
WHERE rn = 1
ORDER BY overall_rating DESC, potential DESC
LIMIT 25;


-- ----------------------------------------------------------------------------
-- QUERY 2: Peak Athletic Performance Age Window
-- Groups player overall ratings by age to identify the global performance peak.
-- Identifies the standard prime window in professional football (~26 to 29 years).
-- ----------------------------------------------------------------------------
WITH player_ages AS (
    SELECT 
        pa.player_api_id,
        pa.overall_rating,
        CAST((JULIANDAY(pa.date) - JULIANDAY(p.birthday)) / 365.25 AS INT) AS age
    FROM Player_Attributes pa
    JOIN Player p ON pa.player_api_id = p.player_api_id
    WHERE pa.overall_rating IS NOT NULL AND p.birthday IS NOT NULL
)
SELECT 
    age,
    COUNT(*) AS total_evaluations,
    ROUND(AVG(overall_rating), 2) AS avg_overall_rating,
    MAX(overall_rating) AS peak_rating_recorded
FROM player_ages
WHERE age BETWEEN 16 AND 38
GROUP BY age
ORDER BY age ASC;


-- ----------------------------------------------------------------------------
-- QUERY 3: Top Wonderkids & Elite Young Prospects (Age <= 21)
-- Identifies young players exhibiting world-class potential ratings (>= 86).
-- ----------------------------------------------------------------------------
WITH latest_evals AS (
    SELECT 
        p.player_name,
        pa.overall_rating,
        pa.potential,
        (pa.potential - pa.overall_rating) AS growth_headroom,
        CAST((JULIANDAY(pa.date) - JULIANDAY(p.birthday)) / 365.25 AS INT) AS age,
        ROW_NUMBER() OVER (PARTITION BY pa.player_api_id ORDER BY pa.date DESC) AS rn
    FROM Player_Attributes pa
    JOIN Player p ON pa.player_api_id = p.player_api_id
    WHERE pa.overall_rating IS NOT NULL
)
SELECT 
    player_name,
    age,
    overall_rating AS current_ability,
    potential AS projected_ceiling,
    growth_headroom
FROM latest_evals
WHERE rn = 1 AND age <= 21 AND potential >= 86
ORDER BY potential DESC, growth_headroom DESC
LIMIT 20;


-- ----------------------------------------------------------------------------
-- QUERY 4: Technical Playmaker Profiling (Short Passing & Vision)
-- Identifies top creative midfielders based on passing vision and ball control.
-- ----------------------------------------------------------------------------
WITH latest_ratings AS (
    SELECT 
        p.player_name,
        pa.short_passing,
        pa.ball_control,
        pa.vision,
        pa.dribbling,
        pa.overall_rating,
        ROW_NUMBER() OVER (PARTITION BY pa.player_api_id ORDER BY pa.date DESC) AS rn
    FROM Player_Attributes pa
    JOIN Player p ON pa.player_api_id = p.player_api_id
    WHERE pa.short_passing IS NOT NULL
)
SELECT 
    player_name,
    overall_rating,
    short_passing,
    ball_control,
    vision,
    dribbling,
    ROUND((short_passing + ball_control + vision + dribbling) / 4.0, 1) AS playmaker_index
FROM latest_ratings
WHERE rn = 1
ORDER BY playmaker_index DESC
LIMIT 20;


-- ----------------------------------------------------------------------------
-- QUERY 5: Left-Footed vs Right-Footed Distribution & Quality
-- Evaluates preferred foot distribution and comparative skill averages.
-- ----------------------------------------------------------------------------
SELECT 
    preferred_foot,
    COUNT(DISTINCT player_api_id) AS total_players,
    ROUND(100.0 * COUNT(DISTINCT player_api_id) / 
          (SELECT COUNT(DISTINCT player_api_id) FROM Player_Attributes WHERE preferred_foot IS NOT NULL), 1) AS foot_share_pct,
    ROUND(AVG(overall_rating), 2) AS avg_overall_rating,
    ROUND(AVG(crossing), 2) AS avg_crossing,
    ROUND(AVG(dribbling), 2) AS avg_dribbling,
    ROUND(AVG(curve), 2) AS avg_curve
FROM Player_Attributes
WHERE preferred_foot IS NOT NULL
GROUP BY preferred_foot;
