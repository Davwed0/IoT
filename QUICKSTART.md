# Quick Start Guide

Get the IoT Learning Environment up and running in 5 minutes!

## Step 1: Prerequisites (1 minute)

Ensure you have:
- Docker (20.10+) and Docker Compose (1.29+)
- 8GB+ RAM available
- 20GB+ disk space

```bash
docker --version
docker compose version
```

## Step 2: Clone and Start (2 minutes)

```bash
# Clone the repository
git clone https://github.com/Davwed0/IoT.git
cd IoT

# Start all services
docker compose up -d

# This will:
# - Build the IoT simulator
# - Pull required images (Hadoop, Hive, ELK)
# - Start all services
# - Begin generating data
```

**Note**: First startup takes 5-10 minutes to download images (~5GB total).

## Step 3: Wait for Services (2 minutes)

Services need time to initialize. Monitor progress:

```bash
# Watch all logs
docker compose logs -f

# Or monitor specific services
docker compose logs -f iot-simulator
docker compose logs -f elasticsearch
```

**Wait for these messages:**
- IoT Simulator: "Starting data generation..."
- Elasticsearch: "started"
- Logstash: "Pipelines running"

## Step 4: Verify Data Flow (30 seconds)

```bash
# Check generated logs
tail -f logs/iot_logs.json

# Check Elasticsearch ingestion (wait 30s after first logs)
curl -X GET "localhost:9200/iot-logs-*/_count?pretty"
```

**Expected**: JSON logs appearing, Elasticsearch count > 0

## Step 5: Access Interfaces (30 seconds)

Open in your browser:

1. **Kibana** (Visualization): http://localhost:5601
   - Go to "Discover" to see logs
   - Create visualizations and dashboards

2. **Hadoop NameNode** (HDFS UI): http://localhost:9870
   - View cluster status and files

3. **Elasticsearch** (API): http://localhost:9200
   - Query data directly via REST API

## Common First-Time Tasks

### View Real-Time Logs

```bash
# Watch simulator output
docker compose logs -f iot-simulator

# Count current logs
wc -l logs/iot_logs.json
```

### Query with Elasticsearch

```bash
# Get latest 5 logs
curl -X GET "localhost:9200/iot-logs-*/_search?pretty&size=5&sort=@timestamp:desc"

# Get error logs only
curl -X GET "localhost:9200/iot-logs-*/_search?pretty" -H 'Content-Type: application/json' -d'
{
  "query": {"match": {"status": "ERROR"}},
  "size": 10
}'

# Get average temperature
curl -X GET "localhost:9200/iot-logs-*/_search?pretty" -H 'Content-Type: application/json' -d'
{
  "size": 0,
  "aggs": {
    "avg_temp": {"avg": {"field": "temp"}}
  }
}'
```

### Setup Kibana (First Time)

```bash
# Run setup script
./elk/kibana/setup-kibana.sh

# Or manually:
# 1. Go to http://localhost:5601
# 2. Navigate to Stack Management → Index Patterns
# 3. Create pattern: "iot-logs-*"
# 4. Select "@timestamp" as time field
# 5. Go to Discover to view logs
```

### Query with Hive

```bash
# Wait for Hive to be ready (takes ~2-3 minutes after startup)
sleep 180

# Connect to Hive
docker exec -it hive-server /opt/hive/bin/beeline -u jdbc:hive2://localhost:10000

# Inside Hive, run:
# CREATE EXTERNAL TABLE IF NOT EXISTS iot_logs (
#     timestamp STRING,
#     device_id STRING,
#     temp FLOAT,
#     humidity FLOAT,
#     status STRING
# )
# ROW FORMAT SERDE 'org.apache.hive.hcatalog.data.JsonSerDe'
# STORED AS TEXTFILE
# LOCATION '/logs/';
#
# SELECT device_id, AVG(temp) as avg_temp
# FROM iot_logs
# GROUP BY device_id;
```

Or use the pre-built scripts:

```bash
# Run analytics
docker exec -it hive-server /opt/hive/bin/beeline -u jdbc:hive2://localhost:10000 -f /hive_custom_scripts/process_logs.hql
```

## Configuration

### Adjust Simulator Parameters

Edit `docker-compose.yml`:

```yaml
iot-simulator:
  environment:
    - DEVICE_COUNT=10        # Change number of devices
    - INTERVAL_SECONDS=10    # Change interval between readings
```

Then restart:

```bash
docker compose restart iot-simulator
```

### Adjust Resource Allocation

Edit `docker-compose.yml`:

```yaml
elasticsearch:
  environment:
    - "ES_JAVA_OPTS=-Xms1g -Xmx1g"  # Increase if you have more RAM
```

## Quick Commands

```bash
# Start everything
make up

# Stop everything
make down

# View logs
make logs

# Check status
make status

# Run health checks
make test

# Clean up (removes all data!)
make clean
```

## Troubleshooting

### Services not starting?

```bash
# Check what's wrong
docker compose ps
docker compose logs <service-name>

# Common fix: increase Docker memory allocation
# Docker Desktop → Settings → Resources → Memory: 8GB+
```

### No logs generated?

```bash
# Check simulator
docker compose logs iot-simulator

# Fix permissions
sudo chmod 777 logs/
docker compose restart iot-simulator
```

### Elasticsearch connection refused?

```bash
# Wait longer (Elasticsearch takes ~60s to start)
sleep 60
curl http://localhost:9200

# Or check logs
docker compose logs elasticsearch
```

### Hive not connecting?

```bash
# Hive takes 2-3 minutes to fully initialize
sleep 180

# Check all Hive components
docker compose ps | grep hive
```

## Next Steps

1. **Explore Kibana**:
   - Create visualizations (line charts, pie charts)
   - Build dashboards
   - Set up alerts

2. **Run Hive Analytics**:
   - Compute hourly statistics
   - Find devices with most errors
   - Analyze temperature trends

3. **Customize**:
   - Modify the C program to add new sensors
   - Add custom Logstash filters
   - Create custom Hive queries

4. **Scale**:
   - Increase device count
   - Add more DataNodes
   - Process historical data

## Learning Path

**Week 1**: Basic Operation
- Start/stop services
- View logs in Kibana
- Run simple queries

**Week 2**: Data Processing
- Create Hive tables
- Write SQL queries
- Compute aggregations

**Week 3**: Advanced Analytics
- Build Kibana dashboards
- Create complex Hive queries
- Monitor system health

**Week 4**: Customization
- Modify IoT simulator
- Add custom sensors
- Create ML models (optional)

## Resources

- **Full Documentation**: See README.md
- **Testing Guide**: See TESTING.md
- **Hive Queries**: See hive/*.hql
- **Logstash Config**: See elk/logstash/pipeline/

## Getting Help

Common issues and solutions:

| Issue | Solution |
|-------|----------|
| Elasticsearch won't start | Increase Docker memory to 8GB+ |
| Hive connection timeout | Wait 3 minutes after startup |
| Logs not appearing | Check `logs/` directory permissions |
| Services crashing | Check `docker compose logs <service>` |
| Slow performance | Reduce DEVICE_COUNT or increase INTERVAL_SECONDS |

## Success Indicators

You're ready to learn when you see:

✅ IoT simulator generating logs every 10 seconds
✅ `logs/iot_logs.json` file growing
✅ Elasticsearch returning search results
✅ Kibana showing logs in Discover
✅ Hadoop NameNode UI accessible at :9870
✅ Hive accepting connections at :10000

**Congratulations! Your IoT Learning Environment is ready! 🎉**

Start exploring with Kibana at http://localhost:5601
