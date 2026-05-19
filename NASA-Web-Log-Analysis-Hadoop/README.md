# 🌐 NASA Web Server Log Analysis - Python Streaming + Hive

End-to-end pipeline on 3,461,612 HTTP requests logged by NASA Kennedy Space Center's web server in July–August 1995. Raw unstructured log lines go in. Structured traffic intelligence and bot detection reports come out.

---

## 📌 Overview

Web server logs are unstructured, massive, and full of signal. This project builds a full two-stage pipeline: Python + Hadoop Streaming parses and aggregates the raw logs, then Apache Hive runs 5 analytical queries on the cleaned output — identifying peak traffic windows, suspicious IPs, high-error URLs, and bandwidth abusers.

---

## 🎯 Objective

- Parse 3.4M unstructured Apache log lines using regex in Python
- Emit two record types per log line: TRAFFIC and SECURITY
- Aggregate per host/hour in the Reducer
- Load output into Hive for analytical querying
- Detect bot activity, brute-force login attempts, and URL scanners

---

## 🛠️ Technologies Used

| Technology | Version | Purpose |
|---|---|---|
| Apache Hadoop | 3.4.1 | Distributed processing |
| Python | 3.x | Log parser (Mapper + Reducer) |
| Hadoop Streaming | 3.4.1 | Python-to-MapReduce bridge |
| Apache Hive | 4.0.1 | Analytical queries on output |
| HDFS | 3.4.1 | Storage |

---

## 📂 Dataset

**NASA Kennedy Space Center Web Server Logs**

| Field | Details |
|---|---|
| Period | July–August 1995 |
| Records | 3,461,612 HTTP requests |
| Format | Unstructured Apache Combined Log Format |

Raw log line:
```
199.72.81.55 - - [01/Jul/1995:00:00:01 -0400] "GET /history/apollo/ HTTP/1.0" 200 6245
```

---

## 🏗️ Pipeline Architecture

```
nasa_jul95.txt + nasa_aug95.txt  (3.4M raw log lines, HDFS)
                    │
                    ▼ mapper.py — regex parser
┌───────────────────────────────────────────────────┐
│  For each log line:                               │
│  Emit TRAFFIC key  →  host | date | hour          │
│  Emit SECURITY key →  SEC | host | date           │
└───────────────────────────┬───────────────────────┘
                            │ Hadoop sorts by key
                            ▼ reducer.py
┌───────────────────────────────────────────────────┐
│  TRAFFIC group  → url, request_count, bytes, errors│
│  SECURITY group → total_req, 401s, 404s, flags     │
└───────────────────────────┬───────────────────────┘
                            │
            ┌───────────────┴───────────────┐
            ▼                               ▼
  traffic_clean.csv                security_clean.csv
            │                               │
            └───────────────┬───────────────┘
                            ▼ Apache Hive
                    5 Analytical Queries
```

---

## 💻 Code Explanation

**mapper.py — regex log parser**
```python
LOG_PATTERN = re.compile(
    r'^(\S+)\s+\S+\s+\S+\s+\[(\d{2}/\w+/\d{4}):(\d{2}).*\]'
    r'\s+"(\S+)\s+(\S+).*"\s+(\d{3})\s+(\S+)'
)
# Emits two record types per line:
print(f"{host}|{date}|{hour}\t{url}|{status}|{bytes}|{method}")   # TRAFFIC
print(f"SEC|{host}|{date}\t{status}|{hour}|{url}")                  # SECURITY
```

**reducer.py — bot detection logic**
```python
if total_requests > 500:    flags.append('BOT_SUSPECTED')
if max_consec_401 >= 3:     flags.append('BRUTE_FORCE_LOGIN')
if total_404s > 50:         flags.append('SCANNER_SUSPECTED')
```

---

## 📊 Hive Queries

| Query | Insight |
|---|---|
| Q1 | Top 20 most requested URLs — hit count + bytes served |
| Q2 | Suspicious IPs with threat score — bot, brute force, scanner |
| Q3 | Hourly traffic distribution — peak load windows |
| Q4 | High-error URLs classified CRITICAL / HIGH / MODERATE |
| Q5 | Top bandwidth-consuming hosts |

---

## 🚀 Run

```bash
hdfs dfs -mkdir -p /nasa/input
hdfs dfs -put nasa_jul95.txt nasa_aug95.txt /nasa/input/

STREAMING_JAR=$(find $HADOOP_HOME -name "hadoop-streaming*.jar" | head -1)

hadoop jar $STREAMING_JAR \
  -input /nasa/input -output /nasa/output \
  -mapper mapper.py -reducer reducer.py \
  -file mapper.py -file reducer.py

hdfs dfs -cat /nasa/output/part-* | grep "^TRAFFIC"  > traffic_clean.csv
hdfs dfs -cat /nasa/output/part-* | grep "^SECURITY" > security_clean.csv

hdfs dfs -put traffic_clean.csv  /nasa/hive/traffic/
hdfs dfs -put security_clean.csv /nasa/hive/security/

hive -f hive_queries.sql
```

---

## 📈 Scalability

| Scale | Approach |
|---|---|
| 3.4M records (demo) | Single-node Streaming + Hive |
| 1B log lines/day | Multi-node cluster, partitioned Hive by date |
| Real-time monitoring | Apache Kafka + Spark Streaming → live threat dashboard |
