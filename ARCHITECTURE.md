# Architecture Overview

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        IoT Learning Environment                          │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────┐
│ IoT Simulator   │  C Program running in Docker
│  (C Language)   │  - Configurable device count
│                 │  - Configurable interval
│  Generates:     │  - Random temperature (15-35°C)
│  - devA1..devZ9 │  - Random humidity (30-90%)
│  - Temp/Humidity│  - Status: OK/WARNING/ERROR
│  - Status       │
└────────┬────────┘
         │ Writes JSON
         ↓
    ┌────────────┐
    │   /logs/   │  Shared Volume
    │iot_logs.json│  - Persisted on host
    └─────┬──┬───┘  - Accessible to all services
          │  │
    ┌─────┘  └──────────┐
    │                   │
    ↓                   ↓
┌───────────────┐  ┌──────────────┐
│ Hadoop/Hive   │  │  Logstash    │
│   Pipeline    │  │   Pipeline   │
└───────────────┘  └──────────────┘

═══════════════════════════════════════════════════════════════════════════
Batch Processing Branch         │    Real-time Processing Branch
(Left Side)                     │    (Right Side)
═══════════════════════════════════════════════════════════════════════════

┌──────────────────────┐        │    ┌─────────────────────────┐
│   Hadoop HDFS        │        │    │      Logstash           │
│   ┌──────────────┐   │        │    │  ┌──────────────────┐   │
│   │  NameNode    │   │        │    │  │ Input: file     │   │
│   │  Port: 9870  │   │        │    │  │ - JSON codec    │   │
│   └──────────────┘   │        │    │  └─────────┬────────┘   │
│   ┌──────────────┐   │        │    │            │            │
│   │  DataNode    │   │        │    │  ┌─────────▼────────┐   │
│   │              │   │        │    │  │ Filters:        │   │
│   └──────────────┘   │        │    │  │ - Parse time    │   │
│                      │        │    │  │ - Categorize    │   │
│  Distributed Storage │        │    │  │ - Tag errors    │   │
└──────────┬───────────┘        │    │  └─────────┬────────┘   │
           │                    │    │            │            │
           ↓                    │    │  ┌─────────▼────────┐   │
┌──────────────────────┐        │    │  │ Output:         │   │
│   Hive Services      │        │    │  │ - Elasticsearch │   │
│  ┌────────────────┐  │        │    │  │ - Console       │   │
│  │ Metastore      │  │        │    │  └──────────────────┘   │
│  │ (PostgreSQL)   │  │        │    └────────────┬────────────┘
│  └────────────────┘  │        │                 │
│  ┌────────────────┐  │        │                 ↓
│  │ Hive Server    │  │        │    ┌─────────────────────────┐
│  │ Port: 10000    │  │        │    │    Elasticsearch        │
│  └────────────────┘  │        │    │   ┌─────────────────┐   │
│                      │        │    │   │ Indices:        │   │
│  SQL Interface       │        │    │   │ iot-logs-*      │   │
│  - Create tables     │        │    │   │                 │   │
│  - Run queries       │        │    │   │ - Search        │   │
│  - Compute stats     │        │    │   │ - Aggregate     │   │
└──────────┬───────────┘        │    │   │ - Store         │   │
           │                    │    │   └─────────────────┘   │
           ↓                    │    │   Port: 9200            │
┌──────────────────────┐        │    └────────────┬────────────┘
│  Analytics Results   │        │                 │
│                      │        │                 ↓
│ Hourly Stats:        │        │    ┌─────────────────────────┐
│ - Avg/Min/Max Temp   │        │    │       Kibana            │
│ - Avg/Min/Max Humid  │        │    │  ┌──────────────────┐   │
│ - Status counts      │        │    │  │ Discover         │   │
│                      │        │    │  │ - View logs      │   │
│ Device Analytics:    │        │    │  └──────────────────┘   │
│ - Per device stats   │        │    │  ┌──────────────────┐   │
│ - Error tracking     │        │    │  │ Visualize        │   │
│ - Trends             │        │    │  │ - Line charts    │   │
│                      │        │    │  │ - Pie charts     │   │
│ Custom Queries:      │        │    │  │ - Metrics        │   │
│ - Temperature trends │        │    │  └──────────────────┘   │
│ - Extreme readings   │        │    │  ┌──────────────────┐   │
│ - Status distribution│        │    │  │ Dashboard        │   │
└──────────────────────┘        │    │  │ - Combined views │   │
                                │    │  │ - Real-time      │   │
                                │    │  └──────────────────┘   │
                                │    │  Port: 5601             │
                                │    └─────────────────────────┘
═══════════════════════════════════════════════════════════════════════════

## Data Flow

### Real-time Path (Seconds)
1. IoT Simulator writes JSON → /logs/iot_logs.json
2. Logstash reads file → parses JSON → filters
3. Elasticsearch indexes → data immediately searchable
4. Kibana visualizes → dashboards update in real-time

### Batch Path (Minutes/Hours)
1. IoT Simulator writes JSON → /logs/iot_logs.json
2. Hive reads from HDFS location (maps to /logs/)
3. Hive executes SQL queries → computes aggregations
4. Results stored in Hive tables → queryable via SQL

## Network Architecture

```
┌─────────────────────────────────────────────┐
│         Docker Network: iot_network          │
│              (Bridge Mode)                   │
│                                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │ namenode │  │ datanode │  │hive-meta-│  │
│  │  :9870   │  │          │  │store-pg  │  │
│  └──────────┘  └──────────┘  └──────────┘  │
│                                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │hive-meta-│  │  hive-   │  │  elastic-│  │
│  │  store   │  │  server  │  │  search  │  │
│  │  :9083   │  │  :10000  │  │  :9200   │  │
│  └──────────┘  └──────────┘  └──────────┘  │
│                                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │ logstash │  │  kibana  │  │   iot-   │  │
│  │  :5000   │  │  :5601   │  │simulator │  │
│  └──────────┘  └──────────┘  └──────────┘  │
│                                              │
└─────────────────────────────────────────────┘
                     │
                     │ Port Mappings
                     ↓
            ┌────────────────┐
            │  Host Machine  │
            │                │
            │  :9870 - HDFS  │
            │  :9200 - ES    │
            │  :5601 - Kibana│
            │  :10000- Hive  │
            └────────────────┘
```

## Storage Architecture

```
┌─────────────────────────────────────────────┐
│           Docker Volumes                     │
│                                              │
│  hadoop_namenode     → HDFS metadata         │
│  hadoop_datanode     → HDFS data blocks      │
│  hive_postgresql     → Hive metastore DB     │
│  elasticsearch_data  → ES indices            │
│                                              │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│           Host Bind Mounts                   │
│                                              │
│  ./logs              → /logs (all services)  │
│  ./hive              → /hive_custom_scripts  │
│  ./elk/logstash/pipe → /usr/share/logstash   │
│                                              │
└─────────────────────────────────────────────┘
```

## Component Responsibilities

### IoT Simulator
- **Function**: Generate realistic IoT device data
- **Input**: Environment variables (DEVICE_COUNT, INTERVAL_SECONDS)
- **Output**: JSON logs to /logs/iot_logs.json
- **Technology**: C program, compiled with GCC

### Hadoop HDFS
- **Function**: Distributed file storage
- **Components**: NameNode (metadata), DataNode (storage)
- **Used By**: Hive for data storage and retrieval
- **Technology**: Apache Hadoop 3.2.1

### Hive
- **Function**: SQL interface for big data processing
- **Components**: Metastore (PostgreSQL), HiveServer2
- **Capabilities**: Table creation, SQL queries, aggregations
- **Technology**: Apache Hive 2.3.2

### Elasticsearch
- **Function**: Search and analytics engine
- **Capabilities**: Full-text search, aggregations, real-time indexing
- **APIs**: REST API on port 9200
- **Technology**: Elasticsearch 8.11.0

### Logstash
- **Function**: Log processing pipeline
- **Pipeline**: Input (file) → Filter (parse/transform) → Output (ES)
- **Configuration**: elk/logstash/pipeline/logstash.conf
- **Technology**: Logstash 8.11.0

### Kibana
- **Function**: Visualization and dashboarding
- **Features**: Discover, Visualize, Dashboard, Dev Tools
- **UI**: Web interface on port 5601
- **Technology**: Kibana 8.11.0

## Deployment Model

```
Development/Learning Environment:
- Single Docker host
- All services on one machine
- Minimal resource requirements (8GB RAM)
- Data persistence via Docker volumes

Production Considerations (Not implemented):
- Multi-node Hadoop cluster
- Elasticsearch cluster (3+ nodes)
- Load balancing
- High availability
- Security (authentication, encryption)
- Monitoring and alerting
- Backup and disaster recovery
```

## Security Model

**Current**: Development/Learning (No security)
- No authentication required
- All services accessible from localhost
- Default configurations
- Suitable for learning environment only

**Production Requirements** (Not implemented):
- Authentication (Kerberos for Hadoop, X-Pack for ELK)
- Authorization (Role-based access control)
- Encryption (TLS/SSL for all communications)
- Network segmentation
- Firewall rules
- Audit logging

## Scaling Considerations

### Horizontal Scaling
- Add more DataNodes: Increase HDFS capacity
- Add more Elasticsearch nodes: Increase search performance
- Add more IoT simulators: Generate more data

### Vertical Scaling
- Increase Java heap sizes (ES_JAVA_OPTS, LS_JAVA_OPTS)
- Increase Docker resource limits
- Use faster storage (SSD)

### Data Management
- Implement data retention policies
- Archive old logs
- Use index lifecycle management (ILM) in Elasticsearch
- Partition Hive tables by date

## Integration Points

### File System
- `/logs/iot_logs.json` - Single source of truth
- Shared via Docker volume mount
- Append-only writes (IoT Simulator)
- Read-only access (Logstash, Hive)

### APIs
- Elasticsearch REST API (port 9200)
- Kibana API (port 5601)
- Hive JDBC (port 10000)
- Hadoop WebUI (port 9870)

### Protocols
- HTTP/REST: Elasticsearch, Kibana, Hadoop UI
- JDBC: Hive connections
- File: Log ingestion

## Monitoring Points

### Health Checks
- Elasticsearch: `/_cluster/health`
- Kibana: `/api/status`
- Hadoop: Port 9870 Web UI
- Hive: JDBC connection test

### Metrics to Monitor
- Log generation rate
- Elasticsearch ingestion lag
- Query performance (Hive, ES)
- Disk usage
- Memory usage
- Error rates

## Learning Progression

1. **Beginner**: Understand data flow, run basic queries
2. **Intermediate**: Write complex queries, build dashboards
3. **Advanced**: Optimize performance, customize pipelines
4. **Expert**: Add new components, implement ML models
