-- table for test matches
CREATE TABLE test_matches (
    match_type TEXT,
    date TEXT,
    inning INTEGER,
    over INTEGER,
    ball INTEGER,
    team TEXT,
    batter TEXT,
    bowler TEXT,
    non_striker TEXT,
    runs_batter INTEGER,
    runs_extras INTEGER,
    total_runs INTEGER,
    dismissal_kind TEXT,
    player_out TEXT
);

-- table for odi matches
CREATE TABLE odi_matches (
    match_type TEXT,
    date TEXT,
    inning INTEGER,
    over INTEGER,
    ball INTEGER,
    team TEXT,
    batter TEXT,
    bowler TEXT,
    non_striker TEXT,
    runs_batter INTEGER,
    runs_extras INTEGER,
    total_runs INTEGER,
    dismissal_kind TEXT,
    player_out TEXT
);

-- table for t20 matches
CREATE TABLE t20_matches (
    match_type TEXT,
    date TEXT,
    inning INTEGER,
    over INTEGER,
    ball INTEGER,
    team TEXT,
    batter TEXT,
    bowler TEXT,
    non_striker TEXT,
    runs_batter INTEGER,
    runs_extras INTEGER,
    total_runs INTEGER,
    dismissal_kind TEXT,
    player_out TEXT
);

-- table for ipl matches
CREATE TABLE ipl_matches (
    match_type TEXT,
    date TEXT,
    inning INTEGER,
    over INTEGER,
    ball INTEGER,
    team TEXT,
    batter TEXT,
    bowler TEXT,
    non_striker TEXT,
    runs_batter INTEGER,
    runs_extras INTEGER,
    total_runs INTEGER,
    dismissal_kind TEXT,
    player_out TEXT
);

-- Table for the test_summary 
CREATE TABLE test_summary (
    match_type TEXT,
    date TEXT,
    venue TEXT,
    team1 TEXT,
    team2 TEXT,
    winner TEXT,
    toss_winner TEXT,
    toss_decision TEXT,
    margin INTEGER,
    margin_type TEXT
);

-- Table for the match_summary 
CREATE TABLE match_summary (
    match_type TEXT,
    date TEXT,
    venue TEXT,
    team1 TEXT,
    team2 TEXT,
    winner TEXT,
    toss_winner TEXT,
    toss_decision TEXT,
    margin INTEGER,
    margin_type TEXT
);