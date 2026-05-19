# Sales Category Revenue Analytics Hadoop Python Streaming

![Hadoop](https://img.shields.io/badge/Apache%20Hadoop-3.4.1-66CCFF) ![Python](https://img.shields.io/badge/Python-3.x-blue) ![Streaming](https://img.shields.io/badge/Hadoop-Streaming-yellow)

## Overview

Analyses a multi-category sales dataset to compute total revenue, transaction count, and average sale value per product category. Written entirely in Python and executed as a distributed MapReduce job via the Hadoop Streaming JAR. No Java, no compilation.

## Objective

- Process multi-category sales CSV from HDFS using Python scripts
- Compute per category: total revenue, number of transactions, average sale value
- Demonstrate Hadoop Streaming as an alternative to Java MapReduce

## Real-World Use Case

| Scenario | Application |
|---|---|
| Retail Analytics | Category-level revenue reporting |
| Sales Operations | Identify best and worst performing categories |
| Finance | Feed aggregated totals into reporting pipelines |
| Data Engineering | Rapid prototyping without Java compilation |

## Technologies Used

| Technology | Version | Purpose |
|---|---|---|
| Apache Hadoop | 3.4.1 | Distributed execution |
| Hadoop Streaming JAR | 3.4.1 | Bridge between Python and MapReduce |
| Python | 3.x | Mapper and Reducer scripts |
| HDFS + YARN | 3.4.1 | Storage + scheduling |

## Architecture

```
+------------------------------------------+
|           INPUT (HDFS)                   |
|       /input/streaming/sales_data.txt    |
+------------------+-----------------------+
                   | stdin line by line
                   v
+------------------------------------------+
|           mapper.py                      |
|  Read CSV line from stdin                |
|  Extract category and price              |
|  Print: category TAB price               |
+------------------+-----------------------+
                   | Hadoop sorts by key
                   v
+------------------------------------------+
|           reducer.py                     |
|  Read sorted key-value pairs             |
|  For each category:                      |
|    sum total, count transactions,        |
|    compute average                       |
|  Print: category | total | count | avg   |
+------------------+-----------------------+
                   v
+------------------------------------------+
|           OUTPUT (HDFS)                  |
|     /output/streaming/part-00000         |
+------------------------------------------+
```

## Code Explanation

**mapper.py**
```python
fields = line.split(",")
category = fields[2]
price = float(fields[4])
print(f"{category}\t{price}")
```
Reads each CSV line from stdin, extracts category and price, prints tab-separated to stdout for Hadoop to sort.

**reducer.py**
```python
if key == current_key:
    total_sales += price
    count += 1
else:
    emit(current_key, total_sales, count)
    current_key = key
    total_sales = price
    count = 1
```
Relies on Hadoop's sorted output guarantee. Detects key change to trigger aggregation and emit.

## Run

```bash
hdfs dfs -mkdir -p /input/streaming
hdfs dfs -put sales_data.txt /input/streaming/

chmod +x mapper.py reducer.py

STREAMING_JAR=$(find $HADOOP_HOME -name "hadoop-streaming*.jar" | head -1)

hadoop jar $STREAMING_JAR \
  -input /input/streaming \
  -output /output/streaming \
  -mapper mapper.py \
  -reducer reducer.py \
  -file mapper.py \
  -file reducer.py

hdfs dfs -cat /output/streaming/part-00000
```

## Sample Output

```
Clothing        | total=$45,200.00    | transactions=38    | avg=$1,189.47
Electronics     | total=$312,500.00   | transactions=14    | avg=$22,321.43
Furniture       | total=$98,750.00    | transactions=22    | avg=$4,488.63
```

**Key Insight:** Electronics generates the highest revenue per transaction despite having the fewest transactions, indicating high-value, low-volume sales behaviour.

## Scalability

| Scale | Approach |
|---|---|
| Small dataset | Single-node pseudo-distributed |
| 100M records | Add DataNodes, increase streaming tasks |
| Real-time | Replace with Kafka + Python consumer |
