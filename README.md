# mapreduce-playground

A collection of Hadoop MapReduce projects built hands-on covering Java MapReduce, Python Streaming, Apache Pig, and Hive analytics on real datasets.

**Stack:** Hadoop 3.4.1 · HDFS · MapReduce · Python 3 · Apache Pig · Apache Hive

---

## Projects

| Folder | What it does | Language |
|---|---|---|
| `wordcount/` | State-wise application count from CSV using MapReduce | Java |
| `sales-partitioner/` | Aggregates total sales per item from transaction data | Java |
| `reducer-side-join/` | Joins Employee + Department CSVs using Reducer-Side Join | Java |
| `mapper-side-join/` | Enriches NYC Taxi trip data with zone lookup using Distributed Cache | Java |
| `python-streaming/` | Category-wise revenue, transaction count, and avg sale via Hadoop Streaming | Python |
| `pig-ipl-analysis/` | IPL cricket data analysis — team wins, top batsmen, bowlers, toss impact | Pig Latin |
| `hive-chicago-crimes/` | 1.4M Chicago crime records — crime patterns, arrest rates, time-of-day analysis | HiveQL |
| `nasa-log-analysis/` | End-to-end pipeline on 3.4M NASA web server logs — bot detection, traffic analysis, error severity | Python + Hive |

---

## Setup

All projects run on a single-node Hadoop cluster.

```bash
start-dfs.sh
start-yarn.sh
jps   # verify NameNode, DataNode, ResourceManager, NodeManager are up
```

Each folder has its own README with exact run commands.

---

## Highlights

- `nasa-log-analysis` is the most complete — regex log parser, dual-output reducer (TRAFFIC + SECURITY records), and 5 Hive queries including a threat-scoring model for bot detection
- `mapper-side-join` uses Hadoop Distributed Cache to broadcast a small lookup file to all mappers — zero reducers needed
- `pig-ipl-analysis` covers 6 analytical queries on IPL match and delivery data entirely in Pig Latin
- `hive-chicago-crimes` runs SQL-style queries on 1.4M crime records to surface COVID-era trends and district-level arrest rates
- `python-streaming` plugs standard Python scripts into Hadoop via the Streaming JAR — no Java required
