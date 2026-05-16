# pig-ipl-analysis

IPL cricket data analysis using Apache Pig. Loads `matches.csv` and `deliveries.csv` from HDFS and extracts six insights using Pig Latin.

## Files

- `ipl_analysis.pig` — full Pig script
- `pig_output.png` — actual HDFS output (top bowlers + top batsmen)

## Datasets

- `matches.csv` — one row per IPL match (season, teams, toss, winner, player of the match)
- `deliveries.csv` — one row per ball bowled (batsman, bowler, runs, dismissal)

## Analyses

1. Matches per season
2. Team-wise win count (sorted descending)
3. Toss impact — does winning toss = winning match?
4. Top Player of the Match award winners
5. Top run-scoring batsmen (all-time IPL)
6. Top wicket-taking bowlers (excludes run outs and retired hurt)

## Output

![Pig Output](pig_output.png)

## Run

```bash
start-dfs.sh && start-yarn.sh

hdfs dfs -mkdir -p /input
hdfs dfs -put matches.csv deliveries.csv /input/

pig -f ipl_analysis.pig
```

## Results stored in HDFS

```
/input/output/team_wins
/input/output/top_batsmen
/input/output/top_bowlers
/input/output/top_pom
```
