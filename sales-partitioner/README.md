# sales-partitioner

Aggregates total sales amount per item from a transaction CSV using Hadoop MapReduce.

## Files

- `SalesPartitioner.java` — Mapper emits (item, sales_amount), Reducer sums per item

## Dataset

CSV format: `Item, Amount`

Example:
```
Item,Amount
Apple,120
Banana,45
Apple,80
```

## Run

```bash
# Compile
javac -classpath $(hadoop classpath) SalesPartitioner.java
jar cf sales.jar wordcount*.class

# Upload data
hdfs dfs -mkdir -p /input/sales
hdfs dfs -put sales_data.csv /input/sales/

# Run
hadoop jar sales.jar wordcount /input/sales /output/sales

# View results
hdfs dfs -cat /output/sales/part-r-00000
```

## Output

```
Apple     200
Banana    45
...
```
