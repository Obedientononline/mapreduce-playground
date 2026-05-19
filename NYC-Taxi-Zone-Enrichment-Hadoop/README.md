# NYC Taxi Trip Zone Enrichment - Hadoop Distributed Cache

![Hadoop](https://img.shields.io/badge/Apache%20Hadoop-3.4.1-66CCFF) ![Java](https://img.shields.io/badge/Java-17-orange) ![Join](https://img.shields.io/badge/Mapper--Side%20Join-Distributed%20Cache-blueviolet)

## Overview

Enriches 1M+ NYC Yellow Taxi trip records with human-readable borough and zone names using a Mapper-Side Join. The zone lookup file is broadcast to every mapper node via Hadoop Distributed Cache and loaded into a HashMap during setup, making this a zero-reducer job that skips the shuffle phase entirely.

## Objective

- Load NYC taxi trip data from HDFS at scale
- Broadcast zone lookup table to all mappers via Distributed Cache
- Resolve numeric location IDs to borough and zone names in memory
- Output enriched trip records with zero reducers and no network shuffle

## Real-World Use Case

| Scenario | Application |
|---|---|
| Ride-hailing Analytics | Enrich trip logs with zone metadata |
| Urban Planning | Analyse borough-level demand patterns |
| Revenue Analytics | Compare fare and tip by pickup zone |
| Route Optimisation | Identify high-traffic origin-destination pairs |

## Technologies Used

| Technology | Version | Purpose |
|---|---|---|
| Apache Hadoop | 3.4.1 | Distributed processing |
| Java | 17 | MapReduce program |
| Distributed Cache | 3.4.1 | Broadcast small lookup file to all nodes |
| HDFS + YARN | 3.4.1 | Storage + scheduling |

## Architecture

```
taxi_zone_lookup.csv (265 rows - small file)
           |
           v
   Hadoop Distributed Cache
   broadcast to ALL mapper nodes
           |
           v
+------------------------------------------+
|         MAPPER setup()                   |
|  Load zone lookup into HashMap           |
|  Key: LocationID -> Value: ZoneInfo      |
+------------------------------------------+
           |
yellowtripdata.csv (1M+ rows - large file)
           |
           v
+------------------------------------------+
|         MAPPER map()                     |
|  For each trip row:                      |
|  puZone = map.get(pickup_location_id)    |
|  doZone = map.get(dropoff_location_id)   |
|  Emit enriched row directly              |
+------------------------------------------+
           |
   setNumReduceTasks(0) -- NO SHUFFLE
           |
           v
+------------------------------------------+
|           OUTPUT (HDFS)                  |
|  date | borough -> enriched trip row     |
+------------------------------------------+
```

## Code Explanation

**Loading lookup into memory during setup()**
```java
protected void setup(Context context) throws IOException {
    URI[] cacheFiles = context.getCacheFiles();
    for (URI uri : cacheFiles) {
        if (uri.getFragment().contains("taxi_zone_lookup"))
            loadZoneLookup(uri.getFragment());
    }
}
```
Runs once per mapper task, not once per row. The entire 265-row lookup fits in memory.

**Joining in-memory during map()**
```java
ZoneInfo puZone = zoneMap.getOrDefault(puLocId,
        new ZoneInfo("Unknown", "Unknown Zone", "Unknown"));
ZoneInfo doZone = zoneMap.getOrDefault(doLocId,
        new ZoneInfo("Unknown", "Unknown Zone", "Unknown"));
context.write(new Text(date + " | " + puZone.borough), new Text(outVal));
```
No network shuffle. Every mapper independently enriches its own slice of the data.

## Run

```bash
javac -classpath $(hadoop classpath) MapperSideJoin.java
jar cf msj.jar MSJ*.class

hdfs dfs -mkdir -p /assignmentinput/msj
hdfs dfs -put taxi_zone_lookup.csv /assignmentinput/msj/
hdfs dfs -put yellowtripdata.csv /assignmentinput/msj/

hadoop jar msj.jar MSJ

hdfs dfs -cat /assignmentoutput/msj/part-m-00000 | head -10
```

## Sample Output

```
2019-01-01 | Manhattan    2019-01-01,00,237,Upper East Side,Manhattan,...
2019-01-01 | Brooklyn     2019-01-01,01,112,Park Slope,Brooklyn,...
```

## Scalability

| Scale | Approach |
|---|---|
| 1M trips | Single-node, works as-is |
| 100M trips | Add DataNodes, mappers scale horizontally |
| 1B+ trips | Same code, more nodes. Distributed Cache handles broadcast regardless of cluster size |
