.PHONY: help build up down restart logs clean status test

help:
	@echo "IoT Learning Environment - Available commands:"
	@echo "  make build    - Build all Docker images"
	@echo "  make up       - Start all services"
	@echo "  make down     - Stop all services"
	@echo "  make restart  - Restart all services"
	@echo "  make logs     - View logs from all services"
	@echo "  make status   - Check status of all services"
	@echo "  make clean    - Stop services and remove volumes (WARNING: deletes data)"
	@echo "  make test     - Run basic health checks"

build:
	docker-compose build

up:
	docker-compose up -d
	@echo "Waiting for services to start..."
	@sleep 10
	@echo "Services started. Access points:"
	@echo "  - Hadoop NameNode: http://localhost:9870"
	@echo "  - Kibana: http://localhost:5601"
	@echo "  - Elasticsearch: http://localhost:9200"
	@echo "  - Hive Server: localhost:10000"

down:
	docker-compose down

restart:
	docker-compose restart

logs:
	docker-compose logs -f

status:
	docker-compose ps

clean:
	docker-compose down -v
	rm -f logs/iot_logs.json

test:
	@echo "Running health checks..."
	@echo "\n1. Checking Elasticsearch..."
	@curl -s http://localhost:9200/_cluster/health?pretty | grep -E '(status|number_of_nodes)' || echo "Elasticsearch not ready"
	@echo "\n2. Checking Hadoop NameNode..."
	@curl -s http://localhost:9870 > /dev/null && echo "NameNode: OK" || echo "NameNode: Not ready"
	@echo "\n3. Checking Kibana..."
	@curl -s http://localhost:5601/api/status > /dev/null && echo "Kibana: OK" || echo "Kibana: Not ready"
	@echo "\n4. Checking log generation..."
	@test -f logs/iot_logs.json && echo "Logs: Generated" || echo "Logs: Not yet generated"
	@echo "\n5. Checking IoT Simulator..."
	@docker-compose logs --tail=5 iot-simulator
