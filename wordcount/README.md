# wordcount

Counts how many applications were submitted per state from a CSV dataset using Hadoop MapReduce.

Not the generic "count words in a text file" example — this reads a structured CSV, extracts a specific column, normalizes it, and aggregates counts by state.

## Files

- `WordCount.java` — Mapper extracts state field (column 3), Reducer sums counts per state

## Dataset

CSV with columns: `ApplicationID, Name, State, ...`

## Run

```bash
# Compile
javac -classpath $(hadoop classpath) WordCount.java
jar cf wordcount.jar wc*.class

# Put input on HDFS
hdfs dfs -mkdir -p /input/wc
hdfs dfs -put your_data.csv /input/wc/

# Run
hadoop jar wordcount.jar wc /input/wc /output/wc

# Check output
hdfs dfs -cat /output/wc/part-r-00000
```

## Output format

```
ANDHRA PRADESH    142
KARNATAKA         89
TAMIL NADU        76
...
```
