#!/bin/bash

# Kibana Dashboard Setup Script
# This script creates index patterns and sample visualizations in Kibana

KIBANA_URL="http://localhost:5601"
ELASTICSEARCH_URL="http://localhost:9200"

echo "Waiting for Kibana to be ready..."
until curl -s "$KIBANA_URL/api/status" > /dev/null; do
    echo "Waiting for Kibana..."
    sleep 5
done

echo "Kibana is ready!"

# Wait a bit more for full initialization
sleep 10

echo "Creating index pattern..."

# Create index pattern
HTTP_CODE=$(curl -X POST "$KIBANA_URL/api/saved_objects/index-pattern/iot-logs" \
  -H "kbn-xsrf: true" \
  -H "Content-Type: application/json" \
  -w "%{http_code}" \
  -o /tmp/kibana_response.json \
  -d '{
    "attributes": {
      "title": "iot-logs-*",
      "timeFieldName": "@timestamp"
    }
  }')

if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 201 ]; then
    echo -e "\n\nIndex pattern created successfully!"
elif [ "$HTTP_CODE" -eq 409 ]; then
    echo -e "\n\nIndex pattern already exists!"
else
    echo -e "\n\nError creating index pattern (HTTP $HTTP_CODE):"
    cat /tmp/kibana_response.json
    echo ""
fi

echo -e "\nKibana is ready at: $KIBANA_URL"
echo "Elasticsearch is ready at: $ELASTICSEARCH_URL"
echo ""
echo "Next steps:"
echo "1. Open Kibana: $KIBANA_URL"
echo "2. Go to Discover to view logs"
echo "3. Go to Dashboard to create visualizations"
echo ""
echo "Suggested visualizations to create:"
echo "- Line chart: Temperature over time"
echo "- Pie chart: Status distribution (OK/WARNING/ERROR)"
echo "- Bar chart: Readings per device"
echo "- Metric: Average temperature"
echo "- Data table: Recent errors"
