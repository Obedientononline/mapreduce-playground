# python-streaming

Category-wise sales analytics using Hadoop Streaming — no Java. Standard Python scripts plugged into MapReduce via the Streaming JAR.

Computes per category: total revenue, number of transactions, average sale value.

## Files

- `mapper.py` — reads CSV lines, emits `category\tprice`
- `reducer.py` — aggregates per category, outputs total, count, avg

## Dataset

CSV format: `date, city, category, product, price, customer`

```
2024-01-01,Mumbai,Electronics,Phone,25000,Priya
2024-01-01,Delhi,Clothing,Shirt,1200,Rahul
```

## Run

```bash
# Upload scripts and data
hdfs dfs -mkdir -p /input/streaming
hdfs dfs -put sales_data.txt /input/streaming/

chmod +x mapper.py reducer.py

# Find streaming jar path
STREAMING_JAR=$(find $HADOOP_HOME -name "hadoop-streaming*.jar" | head -1)

# Run
hadoop jar $STREAMING_JAR \
  -input /input/streaming \
  -output /output/streaming \
  -mapper mapper.py \
  -reducer reducer.py \
  -file mapper.py \
  -file reducer.py

# View results
hdfs dfs -cat /output/streaming/part-00000
```

## Output

```
Clothing        | total=$45,200.00    | transactions=38    | avg=$1,189.47
Electronics     | total=$312,500.00   | transactions=14    | avg=$22,321.43
```
