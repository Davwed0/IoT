#!/bin/bash

# Hive Setup and Query Execution Script

echo "Waiting for Hive Server to be ready..."
sleep 30

echo "Connecting to Hive and setting up tables..."

# Execute the main processing script
docker exec -it hive-server /opt/hive/bin/beeline \
  -u jdbc:hive2://localhost:10000 \
  -f /hive_custom_scripts/process_logs.hql

echo ""
echo "Hive tables created and initial processing complete!"
echo ""
echo "To run additional queries:"
echo "  docker exec -it hive-server /opt/hive/bin/beeline -u jdbc:hive2://localhost:10000 -f /hive_custom_scripts/analytics_queries.hql"
echo ""
echo "To connect interactively:"
echo "  docker exec -it hive-server /opt/hive/bin/beeline -u jdbc:hive2://localhost:10000"
