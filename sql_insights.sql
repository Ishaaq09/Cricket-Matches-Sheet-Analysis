-- query1: Te top 10 batsmen by total runs in ODI matches:
SELECT batter, SUM(runs_batter) AS total_runs
FROM odi_matches
GROUP BY batter
ORDER BY total_runs DESC
LIMIT 10;

-- query2: the top 10 bowlers who took the most wickets in T20 matches
SELECT 
bowler,
COUNT(*) AS wickets
FROM t20_matches
WHERE dismissal_kind IS NOT NULL
GROUP BY bowler
ORDER BY wickets DESC
LIMIT 10;

-- query 3: Team with the highest win percentage in Test cricket
SELECT 
    played.team,
    played.matches_played,
    won.matches_won,
    ROUND(won.matches_won * 100.0 / played.matches_played, 2) AS win_percentage
FROM 
    (
        SELECT team, COUNT(*) AS matches_played
        FROM (
            SELECT team1 AS team FROM test_summary
            UNION ALL
            SELECT team2 AS team FROM test_summary
        ) AS all_teams
        GROUP BY team
    ) AS played
LEFT JOIN 
    (
        SELECT winner AS team, COUNT(*) AS matches_won
        FROM test_summary
        WHERE winner IS NOT NULL
        GROUP BY winner
    ) AS won
ON played.team = won.team
ORDER BY win_percentage DESC;

-- query4: Total number of centuries across all match types
SELECT COUNT(*) AS total_centuries
FROM (
    SELECT batter, date, SUM(runs_batter) AS total_runs
    FROM (
        SELECT batter, date, runs_batter FROM test_matches
        UNION ALL
        SELECT batter, date, runs_batter FROM odi_matches
        UNION ALL
        SELECT batter, date, runs_batter FROM t20_matches
        UNION ALL
        SELECT batter, date, runs_batter FROM ipl_matches
    ) AS all_data
    GROUP BY batter, date
    HAVING total_runs >= 100
) AS century_list;

-- query5: Matches with the narrowest margin of victory
SELECT *
FROM match_summary
WHERE margin IS NOT NULL
ORDER BY margin ASC
LIMIT 5;

-- query6: total matches in each match types(ipl,test,t20,odi)
SELECT match_type, COUNT(*) AS total_matches
FROM match_summary
GROUP BY match_type;

-- query7: Toss decision frequency
SELECT match_type, toss_decision, COUNT(*) AS decision_count
FROM match_summary
GROUP BY match_type, toss_decision
ORDER BY match_type, decision_count DESC;

-- query8: most frequent toss winners
SELECT toss_winner, COUNT(*) AS toss_wins
FROM match_summary
GROUP BY toss_winner
ORDER BY toss_wins DESC
LIMIT 10;

-- query9: most victorious teams overall
SELECT winner, COUNT(*) AS total_wins
FROM match_summary
WHERE winner IS NOT NULL AND winner != 'Draw/No result'
GROUP BY winner
ORDER BY total_wins DESC
LIMIT 10;

-- query10: venues hosting most matches
SELECT venue, COUNT(*) AS matches_hosted
FROM match_summary
GROUP BY venue
ORDER BY matches_hosted DESC
LIMIT 10;

-- query11: most sixes by a batter (T20 matches)
SELECT batter, COUNT(*) AS sixes
FROM t20_matches
WHERE runs_batter = 6
GROUP BY batter
ORDER BY sixes DESC
LIMIT 10;

-- query12: most fours by a batter (ODI matches)
SELECT batter, COUNT(*) AS fours
FROM odi_matches
WHERE runs_batter = 4
GROUP BY batter
ORDER BY fours DESC
LIMIT 10;

-- query13: bowlers with most dot balls (IPL)
SELECT bowler, COUNT(*) AS dot_balls
FROM ipl_matches
WHERE total_runs = 0
GROUP BY bowler
ORDER BY dot_balls DESC
LIMIT 10;

-- query14: players with most dismissals (all match types)
SELECT player_out, COUNT(*) AS dismissals
FROM (
    SELECT player_out FROM test_matches
    UNION ALL
    SELECT player_out FROM odi_matches
    UNION ALL
    SELECT player_out FROM t20_matches
    UNION ALL
    SELECT player_out FROM ipl_matches
)
WHERE player_out IS NOT NULL
GROUP BY player_out
ORDER BY dismissals DESC
LIMIT 10;

-- query15: total runs scored by each team (ODI)
SELECT team, SUM(total_runs) AS total_team_runs
FROM odi_matches
GROUP BY team
ORDER BY total_team_runs DESC
LIMIT 10;

-- query16: team that won most tosses and also won the match (ODI)
SELECT toss_winner, toss_decision, COUNT(*) AS toss_match_wins
FROM match_summary
WHERE toss_winner = winner
GROUP BY toss_winner, toss_decision
ORDER BY toss_match_wins DESC;

-- query17: number of matches decided by wickets
SELECT COUNT(*) AS wickets_victories
FROM match_summary
WHERE margin_type = 'wickets';

-- query18: number of matches decided by runs
SELECT COUNT(*) AS runs_victories
FROM match_summary
WHERE margin_type = 'runs';

-- query19: total boundaries (4s and 6s) in IPL
SELECT 
    SUM(CASE WHEN runs_batter = 4 THEN 1 ELSE 0 END) AS total_fours,
    SUM(CASE WHEN runs_batter = 6 THEN 1 ELSE 0 END) AS total_sixes
FROM ipl_matches;

-- query20: batters with most 50+ scores (All match types)
SELECT batter, COUNT(*) AS fifties_or_more
FROM (
    SELECT batter, date, SUM(runs_batter) AS total_runs
    FROM (
        SELECT batter, date, runs_batter FROM test_matches
        UNION ALL
        SELECT batter, date, runs_batter FROM odi_matches
        UNION ALL
        SELECT batter, date, runs_batter FROM t20_matches
        UNION ALL
        SELECT batter, date, runs_batter FROM ipl_matches
    )
    GROUP BY batter, date
    HAVING total_runs >= 50
)
GROUP BY batter
ORDER BY fifties_or_more DESC
LIMIT 10;