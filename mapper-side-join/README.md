# mapper-side-join

Enriches NYC Yellow Taxi trip records with borough and zone names using a Map-Side Join. The small lookup file (`taxi_zone_lookup.csv`) is broadcast to all mappers via Hadoop Distributed Cache — no reducer needed.

## Files

- `MapperSideJoin.java` — loads zone lookup in `setup()`, joins during `map()`, zero reducers

## Datasets

- `yellowtripdata.csv` — NYC Yellow Taxi trip records
- `taxi_zone_lookup.csv` — LocationID to Borough, Zone, ServiceZone mapping

## How it works

The zone lookup file is small enough to fit in memory. Instead of a shuffle-heavy join, it gets loaded into a `HashMap` by each mapper during `setup()`. Every trip row is enriched on the fly — pickup and dropoff location IDs are resolved to zone names without any reducer.

## Run

```bash
javac -classpath $(hadoop classpath) MapperSideJoin.java
jar cf msj.jar MSJ*.class

hdfs dfs -mkdir -p /assignmentinput/msj
hdfs dfs -put taxi_zone_lookup.csv /assignmentinput/msj/
hdfs dfs -put yellowtripdata.csv /assignmentinput/msj/

hadoop jar msj.jar MSJ

hdfs dfs -cat /assignmentoutput/msj/part-m-00000 | head -5
```

## Output columns

```
date | borough  →  date, hour, puLocId, puZone, puBorough, puServiceZone, doLocId, doZone, doBorough, doServiceZone, distance, fare, tip, total
```
