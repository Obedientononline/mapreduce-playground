# nasa-log-analysis

End-to-end pipeline on NASA Kennedy Space Center web server logs from July–August 1995 — 3,461,612 HTTP requests.

Parses raw unstructured log lines using Python + Hadoop Streaming, then runs 5 analytical Hive queries for traffic analysis, bot detection, and error classification.

## Files

- `mapper.py` — regex-based log parser, emits two record types: TRAFFIC and SECURITY
- `reducer.py` — aggregates per group, outputs structured CSV rows
- `hive_queries.sql` — table creation, data loading, and 5 analytical queries

## Dataset

```
https://ita.ee.lbl.gov/traces/NASA_access_log_Jul95.gz
https://ita.ee.lbl.gov/traces/NASA_access_log_Aug95.gz
```

Raw log format:
```
199.72.81.55 - - [01/Jul/1995:00:00:01 -0400] "GET /history/apollo/ HTTP/1.0" 200 6245
```

## Pipeline

```
Raw logs (.txt)
     ↓
Hadoop Streaming (mapper.py → reducer.py)
     ↓
Two output tables:
  traffic_clean.csv   → host, date, hour, url, request_count, bytes, errors
  security_clean.csv  → host, date, total_requests, 401s, 404s, flags
     ↓
Apache Hive (hive_queries.sql)
     ↓
5 query outputs: top URLs, bot IPs, hourly peaks, error severity, bandwidth abuse
```

## Run

```bash
# 1. Download and rename datasets
mv NASA_access_log_Jul95 nasa_jul95.txt
mv NASA_access_log_Aug95 nasa_aug95.txt

# 2. Upload to HDFS
hdfs dfs -mkdir -p /nasa/input
hdfs dfs -put nasa_jul95.txt nasa_aug95.txt /nasa/input/

# 3. Run Hadoop Streaming
STREAMING_JAR=$(find $HADOOP_HOME -name "hadoop-streaming*.jar" | head -1)

hadoop jar $STREAMING_JAR \
  -input /nasa/input \
  -output /nasa/output \
  -mapper mapper.py \
  -reducer reducer.py \
  -file mapper.py \
  -file reducer.py

# 4. Separate traffic and security records
hdfs dfs -cat /nasa/output/part-* | grep "^TRAFFIC" > traffic_clean.csv
hdfs dfs -cat /nasa/output/part-* | grep "^SECURITY" > security_clean.csv

# 5. Upload cleaned CSVs to Hive input paths
hdfs dfs -mkdir -p /nasa/hive/traffic /nasa/hive/security
hdfs dfs -put traffic_clean.csv /nasa/hive/traffic/
hdfs dfs -put security_clean.csv /nasa/hive/security/

# 6. Run Hive queries
hive -f hive_queries.sql
```

## What the queries find

| Query | Question |
|---|---|
| Q1 | Top 20 most requested URLs by hit count |
| Q2 | Suspicious IPs with threat score (bot detection, brute force login, scanner) |
| Q3 | Hourly traffic distribution — identifies peak load windows |
| Q4 | URLs with high error rates, classified as CRITICAL / HIGH / MODERATE |
| Q5 | Top bandwidth-consuming hosts |
