# State-wise Application Demand Analysis — Hadoop MapReduce

![Hadoop](https://img.shields.io/badge/Apache%20Hadoop-3.4.1-66CCFF) ![Java](https://img.shields.io/badge/Java-17-orange) ![MapReduce](https://img.shields.io/badge/MapReduce-Distributed-green)

## Overview

Processes a structured CSV of applications submitted across India and counts how many were filed per state using Hadoop MapReduce. Simulates a government or enterprise intake pipeline where application volume by geography needs to be tracked at scale.

## Objective

- Parse CSV-formatted application data using Hadoop MapReduce
- Extract and normalise the state field from each record
- Count total applications submitted per state
- Demonstrate Mapper + Combiner + Reducer pipeline with HDFS I/O

## Real-World Use Case

| Scenario | Application |
|---|---|
| Government Portals | Track application load per state for resource allocation |
| Logistics | Measure order demand by region |
| Banking | Monitor loan and account applications by geography |
| Policy Planning | Identify high-demand states for infrastructure investment |

## Technologies Used

| Technology | Version | Purpose |
|---|---|---|
| Apache Hadoop | 3.4.1 | Distributed processing |
| Java | 17 | MapReduce program |
| HDFS | 3.4.1 | Input/output storage |
| YARN | 3.4.1 | Resource management |

## Architecture

```
+------------------------------------------+
|           INPUT (HDFS)                   |
|     /input/wc/applications.csv           |
+------------------+-----------------------+
                   | TextInputFormat (line by line)
                   v
+------------------------------------------+
|              MAPPER                      |
|  Split CSV line by comma                 |
|  Extract column[2] -> State name         |
|  Normalise to UPPERCASE                  |
|  Emit (State, 1)                         |
+------------------+-----------------------+
                   | Local aggregation
                   v
+------------------------------------------+
|             COMBINER                     |
|  Partial sum per state on each node      |
|  Reduces shuffle data volume             |
+------------------+-----------------------+
                   | Shuffle & Sort
                   v
+------------------------------------------+
|             REDUCER                      |
|  Receive (State, [1,1,1,...])            |
|  Sum all values                          |
|  Emit (State, total_count)               |
+------------------+-----------------------+
                   v
+------------------------------------------+
|           OUTPUT (HDFS)                  |
|     /output/wc/part-r-00000              |
+------------------------------------------+
```

## Code Explanation

**Mapper — StateMapper**
```java
protected void map(LongWritable key, Text value, Context context) {
    String line = value.toString();
    if (line.startsWith("Application")) return; // skip header
    String[] fields = line.split(",");
    if (fields.length > 2) {
        String stateName = fields[2].trim().toUpperCase();
        if (!stateName.isEmpty()) {
            state.set(stateName);
            context.write(state, ONE); // emit (STATE, 1)
        }
    }
}
```
Skips the CSV header, extracts column index 2, normalises to uppercase for consistent grouping.

**Reducer — SumReducer**
```java
protected void reduce(Text key, Iterable<IntWritable> values, Context context) {
    int sum = 0;
    for (IntWritable val : values) sum += val.get();
    result.set(sum);
    context.write(key, result);
}
```
Aggregates all partial counts for each state and outputs the final total.

## Run

```bash
# Compile
javac -classpath $(hadoop classpath) WordCount.java
jar cf wordcount.jar wc*.class

# Upload input
hdfs dfs -mkdir -p /input/wc
hdfs dfs -put applications.csv /input/wc/

# Run
hadoop jar wordcount.jar wc /input/wc /output/wc

# View output
hdfs dfs -cat /output/wc/part-r-00000
```

## Sample Output

```
ANDHRA PRADESH      142
KARNATAKA            89
MAHARASHTRA         201
TAMIL NADU           76
UTTAR PRADESH       134
```

**Key Insight:** Maharashtra leads in application volume, indicating higher population density or greater digital access in western India.

## Scalability

| Scale | Approach |
|---|---|
| 10K records | Single-node pseudo-distributed |
| 10M records | Add DataNodes, increase reducers |
| 1B records | Multi-node cluster with YARN tuning |
