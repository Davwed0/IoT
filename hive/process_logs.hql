-- Create external table for IoT logs
CREATE EXTERNAL TABLE IF NOT EXISTS iot_logs (
    timestamp STRING,
    device_id STRING,
    temp FLOAT,
    humidity FLOAT,
    status STRING
)
ROW FORMAT SERDE 'org.apache.hive.hcatalog.data.JsonSerDe'
STORED AS TEXTFILE
LOCATION '/logs/';

-- Create table for hourly statistics
CREATE TABLE IF NOT EXISTS hourly_stats (
    hour STRING,
    avg_temp FLOAT,
    min_temp FLOAT,
    max_temp FLOAT,
    avg_humidity FLOAT,
    min_humidity FLOAT,
    max_humidity FLOAT,
    total_readings INT,
    ok_count INT,
    warning_count INT,
    error_count INT
);

-- Compute hourly statistics
INSERT OVERWRITE TABLE hourly_stats
SELECT 
    substr(timestamp, 1, 13) as hour,
    AVG(temp) as avg_temp,
    MIN(temp) as min_temp,
    MAX(temp) as max_temp,
    AVG(humidity) as avg_humidity,
    MIN(humidity) as min_humidity,
    MAX(humidity) as max_humidity,
    COUNT(*) as total_readings,
    SUM(CASE WHEN status = 'OK' THEN 1 ELSE 0 END) as ok_count,
    SUM(CASE WHEN status = 'WARNING' THEN 1 ELSE 0 END) as warning_count,
    SUM(CASE WHEN status = 'ERROR' THEN 1 ELSE 0 END) as error_count
FROM iot_logs
GROUP BY substr(timestamp, 1, 13)
ORDER BY hour DESC;

-- View recent statistics
SELECT * FROM hourly_stats LIMIT 10;
