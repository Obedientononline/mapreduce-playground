match = LOAD 'hdfs://localhost:9000/input/matches.csv' USING PigStorage(',') AS (id:int, season:int, city:chararray, date:chararray, team1:chararray, team2:chararray, toss_winner:chararray, toss_decision:chararray, result:chararray, dl_applied:int, winner:chararray, win_by_runs:int, win_by_wickets:int, player_of_match:chararray, venue:chararray, umpire1:chararray, umpire2:chararray);

deliveries = LOAD 'hdfs://localhost:9000/input/deliveries.csv' USING PigStorage(',') AS (match_id:int, inning:int, batting_team:chararray, bowling_team:chararray, over:int, ball:int, batsman:chararray, non_striker:chararray, bowler:chararray, is_super_over:int, wide_runs:int, bye_runs:int, legbye_runs:int, noball_runs:int, penalty_runs:int, batsman_runs:int, extra_runs:int, total_runs:int, player_dismissed:chararray, dismissal_kind:chararray, fielder:chararray);

-- Matches per season
grp1 = GROUP match BY season;
per_season = FOREACH grp1 GENERATE group AS season, COUNT(match) AS total;
per_season_sorted = ORDER per_season BY season ASC;
DUMP per_season_sorted;

-- Team wins
wins_only = FILTER match BY winner != '' AND winner != 'NA';
grp2 = GROUP wins_only BY winner;
team_wins = FOREACH grp2 GENERATE group AS team, COUNT(wins_only) AS wins;
team_wins_sorted = ORDER team_wins BY wins DESC;
DUMP team_wins_sorted;

-- Toss impact
toss_yes = FILTER match BY toss_winner == winner;
toss_no = FILTER match BY toss_winner != winner;
toss_yes_grp = GROUP toss_yes ALL;
toss_no_grp = GROUP toss_no ALL;
toss_yes_count = FOREACH toss_yes_grp GENERATE 'YES' AS toss_helped:chararray, COUNT(toss_yes) AS count:long;
toss_no_count = FOREACH toss_no_grp GENERATE 'NO' AS toss_helped:chararray, COUNT(toss_no) AS count:long;
DUMP toss_yes_count;
DUMP toss_no_count;

-- Player of the match
pom = FILTER match BY player_of_match != '' AND player_of_match != 'NA';
grp4 = GROUP pom BY player_of_match;
pom_awards = FOREACH grp4 GENERATE group AS player, COUNT(pom) AS awards;
pom_sorted = ORDER pom_awards BY awards DESC;
DUMP pom_sorted;

-- Top Batsmen
grp5 = GROUP deliveries BY batsman;
run_totals = FOREACH grp5 GENERATE group AS batsman, SUM(deliveries.batsman_runs) AS runs;
run_totals_sorted = ORDER run_totals BY runs DESC;
DUMP run_totals_sorted

-- Top Bowlers
wkts = FILTER deliveries BY player_dismissed != '' AND player_dismissed != 'NA' AND dismissal_kind != 'run out' AND dismissal_kind != 'retired hurt';
grp6 = GROUP wkts BY bowler;
wickets = FOREACH grp6 GENERATE group AS bowler, COUNT(wkts) AS wickets;
wickets_sorted = ORDER wickets BY wickets DESC;
DUMP wickets_sorted;

-- Store results securely in HDFS
STORE team_wins_sorted INTO 'hdfs://localhost:9000/input/output/team_wins' USING PigStorage(',');
STORE run_totals_sorted INTO 'hdfs://localhost:9000/input/output/top_batsmen' USING PigStorage(',');
STORE wickets_sorted INTO 'hdfs://localhost:9000/input/output/top_bowlers' USING PigStorage(',');
STORE pom_sorted INTO 'hdfs://localhost:9000/input/output/top_pom' USING PigStorage(',');
