# mapreduce-playground

![Hadoop](https://img.shields.io/badge/Apache%20Hadoop-3.4.1-66CCFF?logo=apache) ![Java](https://img.shields.io/badge/Java-17-orange?logo=java) ![Python](https://img.shields.io/badge/Python-3.x-blue?logo=python) ![Hive](https://img.shields.io/badge/Apache%20Hive-4.0.1-yellow) ![Pig](https://img.shields.io/badge/Apache%20Pig-0.17-lightgrey)

Hands-on Hadoop ecosystem projects built on a single-node HDFS cluster, covering Java MapReduce, Python Streaming, Apache Pig, and Hive analytics across real-world datasets.

---

## Projects

| Project | Dataset | Technique | Scale |
|---|---|---|---|
| [State-Application-Demand-MapReduce](./State-Application-Demand-MapReduce/) | State-wise application CSV | MapReduce + Combiner | — |
| [Retail-Sales-Aggregation-MapReduce](./Retail-Sales-Aggregation-MapReduce/) | Retail transaction records | MapReduce aggregation | — |
| [Employee-Department-Join-Hadoop](./Employee-Department-Join-Hadoop/) | Employee + Department CSVs | Reducer-Side Join | — |
| [NYC-Taxi-Zone-Enrichment-Hadoop](./NYC-Taxi-Zone-Enrichment-Hadoop/) | NYC Yellow Taxi + Zone lookup | Mapper-Side Join + Distributed Cache | 1M+ rows |
| [Sales-Category-Analytics-Streaming](./Sales-Category-Analytics-Streaming/) | Multi-category sales data | Hadoop Python Streaming | — |
| [IPL-Cricket-Analysis-Apache-Pig](./IPL-Cricket-Analysis-Apache-Pig/) | IPL matches + ball-by-ball data | Apache Pig, 6 analyses | 16 seasons |
| [Chicago-Crime-Pattern-Analysis-Hive](./Chicago-Crime-Pattern-Analysis-Hive/) | Chicago crime records | Apache Hive, 5 queries | 1.4M records |

---

## Stack

| Technology | Version | Purpose |
|---|---|---|
| Apache Hadoop | 3.4.1 | Distributed processing framework |
| HDFS + YARN | 3.4.1 | Distributed storage + resource management |
| Apache Hive | 4.0.1 | SQL-style querying on HDFS |
| Apache Pig | 0.17 | Data flow scripting |
| Java | 17 | MapReduce job language |
| Python | 3.x | Hadoop Streaming scripts |
| Beeline | 4.0.1 | Hive CLI |

---

## Setup

```bash
start-dfs.sh
start-yarn.sh
jps   # NameNode, DataNode, ResourceManager, NodeManager
```

Each project folder has its own README with dataset details, architecture, run commands, and output.
