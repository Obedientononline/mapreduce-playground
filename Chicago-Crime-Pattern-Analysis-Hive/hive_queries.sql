-- Chicago Crime Dataset | 2020-2026 | 1,456,694 Records

-- STEP 3: CREATING TABLE
CREATE TABLE chicago_crimes (
    id                STRING,
    case_number       STRING,
    crime_date        STRING,
    block             STRING,
    lucr              STRING,
    primary_type      STRING,
    description       STRING,
    location_desc     STRING,
    arrest            STRING,
    domestic          STRING,
    beat              STRING,
    district          STRING,
    ward              STRING,
    community_area    STRING,
    fbi_code          STRING,
    x_coordinate      STRING,
    y_coordinate      STRING,
    year              STRING,
    updated_on        STRING
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES (
    "separatorChar" = ",",
    "quoteChar"     = "\""
)
STORED AS TEXTFILE
TBLPROPERTIES ("skip.header.line.count"="1");

-- STEP 4: Load data
LOAD DATA LOCAL INPATH '/home/shivani/Downloads/Crimes.csv'
INTO TABLE chicago_crimes;

-- STEP 5: Year distribution
SELECT year, COUNT(*) AS total
FROM chicago_crimes
GROUP BY year
ORDER BY year;

-- Query 1: Top 10 Crime Types
SELECT primary_type, COUNT(*) AS total_crimes
FROM chicago_crimes
WHERE year BETWEEN '2020' AND '2026'
GROUP BY primary_type
ORDER BY total_crimes DESC
LIMIT 10;

-- Query 2: District-wise Crime & Arrest Rate
SELECT
    district,
    COUNT(*) AS total_crimes,
    SUM(CASE WHEN arrest = 'true' THEN 1 ELSE 0 END) AS arrests,
    ROUND(SUM(CASE WHEN arrest = 'true' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS arrest_pct
FROM chicago_crimes
WHERE year BETWEEN '2020' AND '2026'
GROUP BY district
ORDER BY total_crimes DESC;

-- Query 3: Time-of-Day Pattern
SELECT
    CASE
        WHEN CAST(SPLIT(SPLIT(crime_date, ' ')[1], ':')[0] AS INT) BETWEEN 0  AND 5  THEN 'Late Night'
        WHEN CAST(SPLIT(SPLIT(crime_date, ' ')[1], ':')[0] AS INT) BETWEEN 6  AND 11 THEN 'Morning'
        WHEN CAST(SPLIT(SPLIT(crime_date, ' ')[1], ':')[0] AS INT) BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END AS time_slot,
    COUNT(*) AS total_crimes
FROM chicago_crimes
WHERE year BETWEEN '2020' AND '2026'
GROUP BY
    CASE
        WHEN CAST(SPLIT(SPLIT(crime_date, ' ')[1], ':')[0] AS INT) BETWEEN 0  AND 5  THEN 'Late Night'
        WHEN CAST(SPLIT(SPLIT(crime_date, ' ')[1], ':')[0] AS INT) BETWEEN 6  AND 11 THEN 'Morning'
        WHEN CAST(SPLIT(SPLIT(crime_date, ' ')[1], ':')[0] AS INT) BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END
ORDER BY total_crimes DESC;

-- Query 4: Year-wise Crime Trend (with Domestic Crimes)
SELECT year, COUNT(*) AS total_crimes,
    SUM(CASE WHEN domestic = 'true' THEN 1 ELSE 0 END) AS domestic_crimes
FROM chicago_crimes
WHERE year BETWEEN '2020' AND '2026'
GROUP BY year
ORDER BY year;

-- Query 5: Top 10 Crime Locations
SELECT location_desc, COUNT(*) AS total_crimes
FROM chicago_crimes
WHERE year BETWEEN '2020' AND '2026'
GROUP BY location_desc
ORDER BY total_crimes DESC
LIMIT 10;
