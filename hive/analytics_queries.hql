-- Query 1: Average temperature per device per hour
SELECT 
    substr(timestamp, 1, 13) as hour,
    device_id,
    AVG(temp) as avg_temp,
    AVG(humidity) as avg_humidity,
    COUNT(*) as readings_count
FROM iot_logs
GROUP BY substr(timestamp, 1, 13), device_id
ORDER BY hour DESC, device_id
LIMIT 50;

-- Query 2: Devices with most errors
SELECT 
    device_id,
    COUNT(*) as error_count,
    MAX(timestamp) as last_error
FROM iot_logs
WHERE status = 'ERROR'
GROUP BY device_id
ORDER BY error_count DESC;

-- Query 3: Temperature trends over time
SELECT 
    substr(timestamp, 1, 13) as hour,
    AVG(temp) as avg_temp,
    STDDEV(temp) as temp_stddev
FROM iot_logs
GROUP BY substr(timestamp, 1, 13)
ORDER BY hour DESC
LIMIT 24;

-- Query 4: Status distribution
SELECT 
    status,
    COUNT(*) as count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM iot_logs
GROUP BY status;

-- Query 5: Extreme readings detection
SELECT 
    timestamp,
    device_id,
    temp,
    humidity,
    status
FROM iot_logs
WHERE temp < 18 OR temp > 32 OR humidity < 35 OR humidity > 85
ORDER BY timestamp DESC
LIMIT 20;
