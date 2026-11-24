-- ============================================================================
-- Project: European Football Data Analytics Platform
-- File: 01_schema_and_tables.sql
-- Description: SQLite / Relational Schema Overview, Table Definitions & Keys
-- Dataset: Kaggle European Soccer Database (25,979 matches, 11 leagues, 10k+ players)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Country & League Entities
-- ----------------------------------------------------------------------------
-- Country Table: Holds European nations represented in the database (11 rows)
CREATE TABLE IF NOT EXISTS Country (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE
);

-- League Table: Top-tier championship leagues linked to their country (11 rows)
CREATE TABLE IF NOT EXISTS League (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    country_id INTEGER,
    name TEXT UNIQUE,
    FOREIGN KEY (country_id) REFERENCES Country(id)
);

-- ----------------------------------------------------------------------------
-- 2. Team & Team Attributes Entities
-- ----------------------------------------------------------------------------
-- Team Table: Comprehensive list of European football clubs (299 rows)
CREATE TABLE IF NOT EXISTS Team (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    team_api_id INTEGER UNIQUE,
    team_fifa_api_id INTEGER,
    team_long_name TEXT,
    team_short_name TEXT
);

-- Team_Attributes Table: Tactical play styles and ratings over time (1,458 rows)
CREATE TABLE IF NOT EXISTS Team_Attributes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    team_fifa_api_id INTEGER,
    team_api_id INTEGER,
    date TEXT,
    buildUpPlaySpeed INTEGER,
    buildUpPlaySpeedClass TEXT,
    buildUpPlayDribbling INTEGER,
    buildUpPlayDribblingClass TEXT,
    buildUpPlayPassing INTEGER,
    buildUpPlayPassingClass TEXT,
    buildUpPlayPositioningClass TEXT,
    chanceCreationPassing INTEGER,
    chanceCreationPassingClass TEXT,
    chanceCreationCrossing INTEGER,
    chanceCreationCrossingClass TEXT,
    chanceCreationShooting INTEGER,
    chanceCreationShootingClass TEXT,
    chanceCreationPositioningClass TEXT,
    defencePressure INTEGER,
    defencePressureClass TEXT,
    defenceAggression INTEGER,
    defenceAggressionClass TEXT,
    defenceTeamWidth INTEGER,
    defenceTeamWidthClass TEXT,
    defenceDefenderLineClass TEXT,
    FOREIGN KEY (team_api_id) REFERENCES Team(team_api_id)
);

-- ----------------------------------------------------------------------------
-- 3. Player & Player Attributes Entities
-- ----------------------------------------------------------------------------
-- Player Table: Master register of football players (11,060 rows)
CREATE TABLE IF NOT EXISTS Player (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    player_api_id INTEGER UNIQUE,
    player_name TEXT,
    player_fifa_api_id INTEGER UNIQUE,
    birthday TEXT,
    height NUMERIC,
    weight NUMERIC
);

-- Player_Attributes Table: Periodic EA FIFA rating snapshots (183,978 rows)
CREATE TABLE IF NOT EXISTS Player_Attributes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    player_fifa_api_id INTEGER,
    player_api_id INTEGER,
    date TEXT,
    overall_rating NUMERIC,
    potential NUMERIC,
    preferred_foot TEXT,
    attacking_work_rate TEXT,
    defensive_work_rate TEXT,
    crossing NUMERIC,
    finishing NUMERIC,
    heading_accuracy NUMERIC,
    short_passing NUMERIC,
    volleys NUMERIC,
    dribbling NUMERIC,
    curve NUMERIC,
    free_kick_accuracy NUMERIC,
    long_passing NUMERIC,
    ball_control NUMERIC,
    acceleration NUMERIC,
    sprint_speed NUMERIC,
    agility NUMERIC,
    reactions NUMERIC,
    balance NUMERIC,
    shot_power NUMERIC,
    jumping NUMERIC,
    stamina NUMERIC,
    strength NUMERIC,
    long_shots NUMERIC,
    aggression NUMERIC,
    interceptions NUMERIC,
    positioning NUMERIC,
    vision NUMERIC,
    penalties NUMERIC,
    marking NUMERIC,
    standing_tackle NUMERIC,
    sliding_tackle NUMERIC,
    gk_diving NUMERIC,
    gk_handling NUMERIC,
    gk_kicking NUMERIC,
    gk_positioning NUMERIC,
    gk_reflexes NUMERIC,
    FOREIGN KEY (player_api_id) REFERENCES Player(player_api_id)
);

-- ----------------------------------------------------------------------------
-- 4. Match Entity (Core Transactional Table)
-- ----------------------------------------------------------------------------
-- Match Table: Detailed match events, scores, and lineups (25,979 rows)
CREATE TABLE IF NOT EXISTS Match (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    country_id INTEGER,
    league_id INTEGER,
    season TEXT,
    stage INTEGER,
    date TEXT,
    match_api_id INTEGER UNIQUE,
    home_team_api_id INTEGER,
    away_team_api_id INTEGER,
    home_team_goal INTEGER,
    away_team_goal INTEGER,
    home_player_1 INTEGER,
    home_player_2 INTEGER,
    home_player_3 INTEGER,
    home_player_4 INTEGER,
    home_player_5 INTEGER,
    home_player_6 INTEGER,
    home_player_7 INTEGER,
    home_player_8 INTEGER,
    home_player_9 INTEGER,
    home_player_10 INTEGER,
    home_player_11 INTEGER,
    away_player_1 INTEGER,
    away_player_2 INTEGER,
    away_player_3 INTEGER,
    away_player_4 INTEGER,
    away_player_5 INTEGER,
    away_player_6 INTEGER,
    away_player_7 INTEGER,
    away_player_8 INTEGER,
    away_player_9 INTEGER,
    away_player_10 INTEGER,
    away_player_11 INTEGER,
    goal TEXT,
    shoton TEXT,
    shotoff TEXT,
    foulcommit TEXT,
    card TEXT,
    cross TEXT,
    corner TEXT,
    possession TEXT,
    FOREIGN KEY (country_id) REFERENCES Country(id),
    FOREIGN KEY (league_id) REFERENCES League(id),
    FOREIGN KEY (home_team_api_id) REFERENCES Team(team_api_id),
    FOREIGN KEY (away_team_api_id) REFERENCES Team(team_api_id)
);

-- ----------------------------------------------------------------------------
-- 5. Primary Index Recommendations for Fast Multi-Table Joins
-- ----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_match_league_season ON Match(league_id, season);
CREATE INDEX IF NOT EXISTS idx_match_home_away_teams ON Match(home_team_api_id, away_team_api_id);
CREATE INDEX IF NOT EXISTS idx_player_attributes_player_date ON Player_Attributes(player_api_id, date);
