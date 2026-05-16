-- NASA Web Server Log Analysis
-- Dataset: NASA Kennedy Space Center, July-August 1995, 3,461,612 HTTP requests

-- ============================================================
-- SETUP: Create database and tables
-- ============================================================

CREATE DATABASE IF NOT EXISTS nasa_logs;
USE nasa_logs;

CREATE TABLE IF NOT EXISTS traffic_logs (
    host            STRING,
    log_date        STRING,
    log_hour        STRING,
    url             STRING,
    request_count   INT,
    total_bytes     BIGINT,
    error_count     INT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE;

CREATE TABLE IF NOT EXISTS security_logs (
    host            STRING,
    log_date        STRING,
    total_requests  INT,
    total_401s      INT,
    max_consec_401s INT,
    total_404s      INT,
    security_flag   STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE;

-- Load data (after running Hadoop Streaming job)
LOAD DATA INPATH '/nasa/hive/traffic/traffic_clean.csv' INTO TABLE traffic_logs;
LOAD DATA INPATH '/nasa/hive/security/security_clean.csv' INTO TABLE security_logs;

SELECT COUNT(*) FROM traffic_logs;
SELECT COUNT(*) FROM security_logs;


-- ============================================================
-- QUERY 1: Top 20 most requested URLs
-- ============================================================

SELECT
    url,
    SUM(request_count)                                          AS total_hits,
    SUM(total_bytes)                                            AS total_bytes_served,
    ROUND(SUM(total_bytes) / 1073741824.0, 3)                  AS total_gb,
    SUM(error_count)                                            AS total_errors,
    ROUND(SUM(error_count) * 100.0 /
          NULLIF(SUM(request_count), 0), 2)                    AS error_rate_pct
FROM traffic_logs
GROUP BY url
ORDER BY total_hits DESC
LIMIT 20;


-- ============================================================
-- QUERY 2: Bot and suspicious IP detection with threat scoring
-- ============================================================

SELECT
    host,
    log_date,
    total_requests,
    total_401s,
    total_404s,
    max_consec_401s,
    security_flag,
    ROUND(
        (CASE WHEN total_requests > 1000 THEN 40
              WHEN total_requests > 500  THEN 20
              ELSE 0 END) +
        (CASE WHEN max_consec_401s >= 3  THEN 35 ELSE 0 END) +
        (CASE WHEN total_404s > 100      THEN 25
              WHEN total_404s > 50       THEN 15
              ELSE 0 END)
    , 0) AS threat_score
FROM security_logs
WHERE security_flag != 'NORMAL'
ORDER BY threat_score DESC
LIMIT 20;


-- ============================================================
-- QUERY 3: Hourly traffic distribution
-- ============================================================

SELECT
    log_hour,
    SUM(request_count)          AS total_requests,
    COUNT(DISTINCT host)        AS unique_hosts,
    SUM(error_count)            AS total_errors,
    CASE
        WHEN SUM(request_count) > 100000 THEN 'PEAK'
        WHEN SUM(request_count) > 50000  THEN 'HIGH'
        WHEN SUM(request_count) > 20000  THEN 'MODERATE'
        ELSE 'LOW'
    END AS traffic_category
FROM traffic_logs
GROUP BY log_hour
ORDER BY CAST(log_hour AS INT);


-- ============================================================
-- QUERY 4: High-error URLs with severity classification
-- ============================================================

SELECT
    url,
    SUM(request_count)                                          AS total_requests,
    SUM(error_count)                                            AS total_errors,
    ROUND(SUM(error_count) * 100.0 /
          NULLIF(SUM(request_count), 0), 2)                    AS error_rate_pct,
    CASE
        WHEN SUM(error_count) * 100.0 / NULLIF(SUM(request_count), 0) > 50 THEN 'CRITICAL'
        WHEN SUM(error_count) * 100.0 / NULLIF(SUM(request_count), 0) > 20 THEN 'HIGH'
        ELSE 'MODERATE'
    END AS error_severity
FROM traffic_logs
WHERE request_count > 10
GROUP BY url
HAVING error_rate_pct > 10
ORDER BY error_rate_pct DESC
LIMIT 20;


-- ============================================================
-- QUERY 5: Bandwidth abuse detection
-- ============================================================

SELECT
    host,
    SUM(request_count)                          AS total_requests,
    SUM(total_bytes)                            AS total_bytes,
    ROUND(SUM(total_bytes) / 1048576.0, 2)     AS total_mb
FROM traffic_logs
GROUP BY host
ORDER BY total_bytes DESC
LIMIT 20;


-- ============================================================
-- EXPORT RESULTS
-- ============================================================

hive -e "SELECT * FROM nasa_logs.security_logs WHERE security_flag != 'NORMAL' ORDER BY total_requests DESC" \
  > ~/Downloads/suspected_bots.csv

hive -e "SELECT url, SUM(request_count) AS hits FROM nasa_logs.traffic_logs GROUP BY url ORDER BY hits DESC LIMIT 20" \
  > ~/Downloads/top_urls.csv

hive -e "SELECT log_hour, SUM(request_count) AS reqs FROM nasa_logs.traffic_logs GROUP BY log_hour ORDER BY CAST(log_hour AS INT)" \
  > ~/Downloads/hourly_traffic.csv
