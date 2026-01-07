# Testing Guide

This guide provides instructions for testing the IoT Learning Environment.

## Prerequisites Testing

Before starting, verify you have the required tools:

```bash
# Check Docker version (should be 20.10+)
docker --version

# Check Docker Compose version (should be 1.29+ or 2.0+)
docker compose version

# Check available resources
docker system info | grep -E "(CPUs|Total Memory)"
```

## Basic Functionality Tests

### Test 1: C Program Compilation

```bash
# Compile the IoT simulator
gcc -o /tmp/iot_simulator src/iot_simulator.c

# Verify compilation
ls -lh /tmp/iot_simulator
```

**Expected**: Executable created without errors

### Test 2: Docker Compose Configuration

```bash
# Validate docker-compose.yml
docker compose config > /dev/null

# List all services
docker compose config --services
```

**Expected**: No errors, lists all 9 services

### Test 3: Build IoT Simulator Image

```bash
# Build only the IoT simulator image
docker compose build iot-simulator
```

**Expected**: Image builds successfully

## Integration Tests

### Test 4: Start Core Services

```bash
# Start Elasticsearch first (required by others)
docker compose up -d elasticsearch

# Wait for Elasticsearch to be ready
sleep 30

# Check Elasticsearch health
curl -X GET "localhost:9200/_cluster/health?pretty"
```

**Expected**: Elasticsearch status "yellow" or "green"

### Test 5: Start ELK Stack

```bash
# Start Logstash and Kibana
docker compose up -d logstash kibana

# Wait for services
sleep 30

# Check Logstash
curl -X GET "localhost:9600/?pretty"

# Check Kibana
curl -I http://localhost:5601/api/status
```

**Expected**: All services respond with HTTP 200

### Test 6: Start IoT Simulator

```bash
# Start the simulator
docker compose up -d iot-simulator

# Check logs
docker compose logs -f iot-simulator

# Wait for log generation
sleep 20

# Verify logs exist
ls -lh logs/iot_logs.json
tail -5 logs/iot_logs.json
```

**Expected**: 
- JSON logs generated in logs/iot_logs.json
- Format: `{"timestamp":"...","device_id":"...","temp":...,"humidity":...,"status":"..."}`

### Test 7: Verify Logstash Processing

```bash
# Check Logstash logs for processing
docker compose logs logstash | grep -i "iot-logs"

# Query Elasticsearch for ingested data
curl -X GET "localhost:9200/iot-logs-*/_search?pretty" -H 'Content-Type: application/json' -d'
{
  "size": 5,
  "sort": [{"@timestamp": "desc"}]
}'
```

**Expected**: Recent logs visible in Elasticsearch

### Test 8: Start Hadoop and Hive

```bash
# Start Hadoop services
docker compose up -d namenode datanode

# Wait for Hadoop to initialize
sleep 60

# Check NameNode
curl http://localhost:9870

# Start Hive services
docker compose up -d hive-metastore-postgresql hive-metastore hive-server

# Wait for Hive to be ready
sleep 120

# Test Hive connection
docker exec -it hive-server /opt/hive/bin/beeline -u jdbc:hive2://localhost:10000 -e "SHOW DATABASES;"
```

**Expected**: Hive connects and shows default database

## Functional Tests

### Test 9: Create and Query Hive Tables

```bash
# Create tables and load data
docker exec -it hive-server /opt/hive/bin/beeline -u jdbc:hive2://localhost:10000 -f /hive_custom_scripts/process_logs.hql

# Query hourly statistics
docker exec -it hive-server /opt/hive/bin/beeline -u jdbc:hive2://localhost:10000 -e "SELECT * FROM hourly_stats LIMIT 5;"
```

**Expected**: Statistics computed from logs

### Test 10: Kibana Dashboard Setup

```bash
# Run Kibana setup script
./elk/kibana/setup-kibana.sh

# Verify index pattern created
curl -X GET "localhost:5601/api/saved_objects/index-pattern/iot-logs" -H 'kbn-xsrf: true'
```

**Expected**: Index pattern exists in Kibana

### Test 11: Data Flow End-to-End

```bash
# Generate specific test pattern
docker compose restart iot-simulator

# Wait for data generation
sleep 30

# Verify in logs file
tail -20 logs/iot_logs.json | jq .

# Verify in Elasticsearch
curl -X GET "localhost:9200/iot-logs-*/_count?pretty"

# Verify in Hive (after copying to HDFS)
docker exec -it hive-server /opt/hive/bin/beeline -u jdbc:hive2://localhost:10000 -e "SELECT COUNT(*) FROM iot_logs;"
```

**Expected**: Data flows through all systems

## Performance Tests

### Test 12: High Volume Data Generation

```bash
# Modify docker-compose.yml to increase load
# Change DEVICE_COUNT to 50 and INTERVAL_SECONDS to 1

# Restart simulator
docker compose up -d iot-simulator

# Monitor system resources
docker stats --no-stream

# Check log file size
watch -n 5 'ls -lh logs/iot_logs.json'
```

**Expected**: System handles increased load without errors

### Test 13: Query Performance

```bash
# Time a Hive query
time docker exec -it hive-server /opt/hive/bin/beeline -u jdbc:hive2://localhost:10000 -e "SELECT device_id, AVG(temp) FROM iot_logs GROUP BY device_id;"

# Time an Elasticsearch query
time curl -X GET "localhost:9200/iot-logs-*/_search?pretty" -H 'Content-Type: application/json' -d'
{
  "size": 0,
  "aggs": {
    "avg_temp": {"avg": {"field": "temp"}}
  }
}'
```

**Expected**: Queries complete in reasonable time

## Error Scenarios

### Test 14: Service Recovery

```bash
# Stop Elasticsearch
docker compose stop elasticsearch

# Wait and observe Logstash behavior
docker compose logs logstash

# Restart Elasticsearch
docker compose start elasticsearch

# Verify recovery
sleep 30
curl -X GET "localhost:9200/_cluster/health?pretty"
```

**Expected**: Services recover gracefully

### Test 15: Invalid Data Handling

```bash
# Add invalid JSON to logs
echo 'INVALID JSON LINE' >> logs/iot_logs.json

# Check Logstash error handling
docker compose logs logstash | grep -i error
```

**Expected**: Logstash handles errors gracefully

## Cleanup Tests

### Test 16: Graceful Shutdown

```bash
# Stop all services
docker compose down

# Verify all containers stopped
docker compose ps
```

**Expected**: All containers stopped cleanly

### Test 17: Data Persistence

```bash
# Stop services
docker compose down

# Restart services
docker compose up -d

# Verify data still exists
curl -X GET "localhost:9200/iot-logs-*/_count?pretty"
```

**Expected**: Previously ingested data remains

### Test 18: Complete Cleanup

```bash
# Remove all data and volumes
docker compose down -v

# Verify volumes removed
docker volume ls | grep iot
```

**Expected**: All volumes removed

## Continuous Testing

### Automated Health Check Script

```bash
# Create a monitoring script
cat > /tmp/monitor.sh << 'EOF'
#!/bin/bash
echo "=== IoT Environment Health Check ==="
echo ""
echo "1. Elasticsearch:"
curl -s http://localhost:9200/_cluster/health | jq -r '.status'
echo ""
echo "2. Kibana:"
curl -s -o /dev/null -w "%{http_code}" http://localhost:5601/api/status
echo ""
echo "3. Hadoop NameNode:"
curl -s -o /dev/null -w "%{http_code}" http://localhost:9870
echo ""
echo "4. Log file size:"
ls -lh logs/iot_logs.json 2>/dev/null | awk '{print $5}'
echo ""
echo "5. IoT Simulator status:"
docker compose ps iot-simulator | grep Up > /dev/null && echo "Running" || echo "Stopped"
EOF

chmod +x /tmp/monitor.sh

# Run every 60 seconds
watch -n 60 /tmp/monitor.sh
```

## Troubleshooting Test Failures

### If Elasticsearch won't start:
```bash
# Check logs
docker compose logs elasticsearch

# Increase memory
# Edit docker-compose.yml: ES_JAVA_OPTS=-Xms1g -Xmx1g
```

### If Hive connection fails:
```bash
# Wait longer for initialization
sleep 180

# Check all Hive components
docker compose logs hive-metastore-postgresql
docker compose logs hive-metastore
docker compose logs hive-server
```

### If logs aren't generated:
```bash
# Check simulator logs
docker compose logs iot-simulator

# Verify permissions
ls -ld logs/
chmod 777 logs/
```

## Test Coverage Summary

- ✅ C program compilation
- ✅ Docker Compose validation
- ✅ Service startup
- ✅ Data generation
- ✅ ELK ingestion
- ✅ Hadoop/Hive processing
- ✅ Query execution
- ✅ Error handling
- ✅ Performance
- ✅ Data persistence

## Expected Results

After all tests pass:
- IoT simulator generates ~600 logs/hour (10 devices, 10s interval)
- Elasticsearch contains all generated logs
- Kibana visualizes data in real-time
- Hive computes hourly statistics
- System runs stably for extended periods
