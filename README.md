# IoT Learning Environment

A comprehensive Docker-based learning environment integrating Hadoop, Hive, and ELK Stack for IoT data processing and analytics.

## Overview

This project simulates multiple IoT devices generating structured JSON logs, which are then processed and analyzed using:
- **Hadoop & Hive**: For batch processing and statistical analysis
- **ELK Stack**: For real-time log ingestion, visualization, and monitoring
- **C Program**: IoT device simulator with configurable parameters

## Architecture

```
IoT Simulator (C) → JSON Logs → {
    ├─ Hadoop/Hive: Batch processing & stats (avg temp/hour, etc.)
    └─ ELK Stack: Real-time ingestion & visualization
}
```

### Components

1. **IoT Simulator**: C program that generates structured JSON logs
   - Configurable device count
   - Configurable interval
   - Outputs: `{"timestamp":"2026-01-07T12:00Z","device_id":"devA1","temp":23.5,"humidity":60,"status":"OK"}`

2. **Hadoop Cluster**:
   - NameNode: HDFS management (port 9870)
   - DataNode: Data storage

3. **Hive**:
   - Hive Server: SQL query interface (port 10000)
   - Metastore: Metadata storage with PostgreSQL backend
   - Pre-configured tables and analytics queries

4. **ELK Stack**:
   - Elasticsearch: Data storage and search (port 9200)
   - Logstash: Log processing pipeline (port 5000)
   - Kibana: Visualization dashboard (port 5601)

## Prerequisites

- Docker (version 20.10+)
- Docker Compose (version 1.29+)
- At least 8GB RAM available for Docker
- At least 20GB disk space

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/Davwed0/IoT.git
cd IoT
```

### 2. Start the Environment

```bash
docker-compose up -d
```

This will:
- Build the IoT simulator
- Start all services (Hadoop, Hive, Elasticsearch, Logstash, Kibana)
- Begin generating IoT logs

### 3. Check Service Status

```bash
docker-compose ps
```

All services should show as "Up" or "healthy".

### 4. View Logs

```bash
# View IoT simulator logs
docker-compose logs -f iot-simulator

# View Logstash processing
docker-compose logs -f logstash

# Check generated log files
tail -f logs/iot_logs.json
```

## Configuration

### IoT Simulator Configuration

Edit `docker-compose.yml` to change simulator parameters:

```yaml
iot-simulator:
  environment:
    - DEVICE_COUNT=10        # Number of simulated devices
    - INTERVAL_SECONDS=10    # Seconds between readings
```

Default: 10 devices, 10-second intervals

### Device Naming

Devices are automatically named as `devA1`, `devA2`, ..., `devB1`, etc.

### Log Format

```json
{
  "timestamp": "2026-01-07T12:00:00Z",
  "device_id": "devA1",
  "temp": 23.5,
  "humidity": 60,
  "status": "OK"
}
```

Status values: `OK` (90%), `WARNING` (5%), `ERROR` (5%)

## Using Hadoop and Hive

### Access Hive

```bash
# Connect to Hive Server container
docker exec -it hive-server bash

# Start Hive CLI
/opt/hive/bin/beeline -u jdbc:hive2://localhost:10000
```

### Run Analytics Queries

```bash
# Inside Hive container
hive -f /hive_custom_scripts/process_logs.hql
```

### Available Queries

1. **process_logs.hql**: Compute hourly statistics
   - Average, min, max temperature per hour
   - Average, min, max humidity per hour
   - Status counts (OK, WARNING, ERROR)

2. **analytics_queries.hql**: Advanced analytics
   - Temperature per device per hour
   - Devices with most errors
   - Temperature trends
   - Status distribution
   - Extreme readings detection

### Example Hive Queries

```sql
-- View hourly statistics
SELECT * FROM hourly_stats LIMIT 10;

-- Find devices with errors
SELECT device_id, COUNT(*) as error_count 
FROM iot_logs 
WHERE status = 'ERROR' 
GROUP BY device_id;

-- Average temperature by hour
SELECT substr(timestamp, 1, 13) as hour, AVG(temp) as avg_temp
FROM iot_logs
GROUP BY substr(timestamp, 1, 13)
ORDER BY hour DESC;
```

## Using ELK Stack

### Access Kibana

1. Open browser: http://localhost:5601
2. Navigate to "Discover" to view logs
3. Create visualizations and dashboards

### Default Index Pattern

- Index: `iot-logs-*`
- Time field: `@timestamp`

### Kibana Setup

1. **Create Index Pattern**:
   - Go to Stack Management → Index Patterns
   - Create pattern: `iot-logs-*`
   - Select `@timestamp` as time field

2. **Create Visualizations**:
   - Temperature trends over time (Line chart)
   - Status distribution (Pie chart)
   - Device activity (Bar chart)
   - Error tracking (Data table)

3. **Create Dashboard**:
   - Combine visualizations
   - Add filters for device_id, status
   - Set auto-refresh interval

### Elasticsearch Queries

```bash
# Check indices
curl -X GET "localhost:9200/_cat/indices?v"

# Query logs
curl -X GET "localhost:9200/iot-logs-*/_search?pretty" -H 'Content-Type: application/json' -d'
{
  "query": {
    "match": { "status": "ERROR" }
  },
  "size": 10
}'

# Aggregation: Average temp per device
curl -X GET "localhost:9200/iot-logs-*/_search?pretty" -H 'Content-Type: application/json' -d'
{
  "size": 0,
  "aggs": {
    "devices": {
      "terms": { "field": "device_id.keyword" },
      "aggs": {
        "avg_temp": { "avg": { "field": "temp" } }
      }
    }
  }
}'
```

## Monitoring Pipeline Health

### Check Service Health

```bash
# Hadoop NameNode
curl http://localhost:9870

# Hive Server
curl http://localhost:10002

# Elasticsearch
curl http://localhost:9200/_cluster/health?pretty

# Kibana
curl http://localhost:5601/api/status
```

### Monitor Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f elasticsearch
docker-compose logs -f logstash
docker-compose logs -f hive-server
```

### Resource Usage

```bash
# Container stats
docker stats

# Disk usage
docker system df
```

## Troubleshooting

### Services Won't Start

```bash
# Check logs
docker-compose logs

# Restart specific service
docker-compose restart <service-name>

# Rebuild and restart
docker-compose up -d --build
```

### No Logs Generated

```bash
# Check IoT simulator
docker-compose logs iot-simulator

# Verify logs directory
ls -la logs/

# Check permissions
chmod 777 logs/
```

### Hive Connection Issues

```bash
# Wait for services to be ready
docker-compose logs hive-metastore
docker-compose logs hive-metastore-postgresql

# Restart Hive services
docker-compose restart hive-metastore hive-server
```

### Elasticsearch Issues

```bash
# Check cluster health
curl http://localhost:9200/_cluster/health?pretty

# Check indices
curl http://localhost:9200/_cat/indices?v

# Clear old data (if needed)
curl -X DELETE "localhost:9200/iot-logs-*"
```

## Stopping the Environment

```bash
# Stop all services
docker-compose down

# Stop and remove volumes (WARNING: deletes all data)
docker-compose down -v
```

## Data Persistence

Data is persisted in Docker volumes:
- `hadoop_namenode`: HDFS metadata
- `hadoop_datanode`: HDFS data blocks
- `hive_postgresql`: Hive metastore
- `elasticsearch_data`: Elasticsearch indices

Logs are stored in `./logs/` directory on the host.

## Learning Objectives

This environment helps you learn:

1. **IoT Data Generation**: Understanding device simulation and log formatting
2. **Distributed Storage**: Hadoop HDFS concepts and operations
3. **Data Warehousing**: Hive table creation and SQL queries
4. **Real-time Processing**: Logstash pipelines and filtering
5. **Search & Analytics**: Elasticsearch queries and aggregations
6. **Visualization**: Kibana dashboards and monitoring
7. **Container Orchestration**: Docker Compose multi-service setups

## Advanced Usage

### Custom Logstash Filters

Edit `elk/logstash/pipeline/logstash.conf` to add custom processing logic.

### Scale IoT Devices

```bash
# Modify docker-compose.yml
environment:
  - DEVICE_COUNT=50
  - INTERVAL_SECONDS=5

# Restart simulator
docker-compose restart iot-simulator
```

### Add More DataNodes

Edit `docker-compose.yml` to add additional datanode services.

### Custom Hive Queries

1. Create `.hql` files in `hive/` directory
2. Run: `docker exec -it hive-server hive -f /hive_custom_scripts/your_query.hql`

## Architecture Diagram

```
┌─────────────────┐
│  IoT Simulator  │
│   (C Program)   │
└────────┬────────┘
         │
         ↓ JSON Logs
    ┌────────┐
    │ /logs/ │
    └───┬─┬──┘
        │ │
    ┌───┘ └───────┐
    ↓             ↓
┌────────┐   ┌─────────┐
│ Hadoop │   │Logstash │
│  Hive  │   └────┬────┘
└───┬────┘        │
    │             ↓
    │      ┌──────────────┐
    │      │Elasticsearch │
    │      └──────┬───────┘
    │             │
    │             ↓
    │        ┌────────┐
    │        │ Kibana │
    │        └────────┘
    ↓
[Statistics]  [Dashboards]
[Analytics]   [Monitoring]
```

## Contributing

Feel free to submit issues and enhancement requests!

## License

This project is for educational purposes.