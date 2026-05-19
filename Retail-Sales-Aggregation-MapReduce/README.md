# Retail Sales Aggregation - Hadoop MapReduce

![Hadoop](https://img.shields.io/badge/Apache%20Hadoop-3.4.1-66CCFF) ![Java](https://img.shields.io/badge/Java-17-orange) ![MapReduce](https://img.shields.io/badge/MapReduce-Distributed-green)

## Overview

Processes a retail transaction CSV and computes total sales revenue per product item using Hadoop MapReduce. Simulates a merchandising analytics pipeline where category managers need aggregated sales figures across distributed transaction logs.

## Objective

- Parse transaction records from HDFS-stored CSV
- Aggregate total sales amount per product item
- Output ranked item-wise revenue summary

## Real-World Use Case

| Scenario | Application |
|---|---|
| Retail Chains | Identify top-selling vs slow-moving SKUs |
| Inventory Planning | Prioritise restocking based on sales volume |
| Revenue Reporting | Feed item-level totals into finance dashboards |
| Category Management | Compare performance across product lines |

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
|       /input/sales/sales_data.csv        |
+------------------+-----------------------+
                   | TextInputFormat
                   v
+------------------------------------------+
|              MAPPER                      |
|  Split line by comma                     |
|  Extract column[0] -> Item name          |
|  Extract column[1] -> Sale amount        |
|  Emit (Item, amount)                     |
+------------------+-----------------------+
                   | Shuffle & Sort
                   v
+------------------------------------------+
|             REDUCER                      |
|  Receive (Item, [120, 80, 45, ...])      |
|  Sum all values                          |
|  Emit (Item, total_revenue)              |
+------------------+-----------------------+
                   v
+------------------------------------------+
|           OUTPUT (HDFS)                  |
|     /output/sales/part-r-00000           |
+------------------------------------------+
```

## Code Explanation

**Mapper — wordmapper**
```java
public void map(LongWritable key, Text value, Context context) {
    String[] colvalue = line.split(",");
    if (colvalue[0].equals("Item")) return; // skip header
    String item = colvalue[0];
    int amount = Integer.parseInt(colvalue[1].trim());
    itemKey.set(item);
    salesValue.set(amount);
    context.write(itemKey, salesValue); // emit (Item, amount)
}
```
Splits each CSV line, skips the header row, emits item name as key and sale amount as value.

**Reducer — wordreducer**
```java
public void reduce(Text key, Iterable<IntWritable> values, Context context) {
    int total = 0;
    for (IntWritable val : values) total += val.get();
    context.write(new Text(key), new IntWritable(total));
}
```
Sums all sale amounts per item across every transaction in the dataset.

## Run

```bash
javac -classpath $(hadoop classpath) SalesPartitioner.java
jar cf sales.jar wordcount*.class

hdfs dfs -mkdir -p /input/sales
hdfs dfs -put sales_data.csv /input/sales/

hadoop jar sales.jar wordcount /input/sales /output/sales

hdfs dfs -cat /output/sales/part-r-00000
```

## Sample Output

```
Apple        200
Banana        45
Laptop      8750
Phone       6200
Tablet      3100
```

## Scalability

| Scale | Approach |
|---|---|
| Small CSV | Single-node pseudo-distributed |
| 100M transactions | Multi-node cluster, partitioner by category |
| Real-time | Replace with Kafka + Spark Streaming |
