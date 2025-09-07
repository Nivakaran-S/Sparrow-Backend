#!/bin/bash

echo "Setting up Local Logistics Microservices Environment..."

# Create necessary directories
echo "Creating configuration directories..."
mkdir -p config
mkdir -p scripts
mkdir -p data/postgres
mkdir -p data/mongo
mkdir -p data/redis
mkdir -p data/kafka

# Make scripts executable
chmod +x scripts/*.sh

echo "Starting infrastructure services first..."

# Start infrastructure services (databases, message queues, etc.)
docker-compose up -d postgres mongo redis zookeeper kafka

echo "Waiting for infrastructure services to be ready..."

# Wait for PostgreSQL
echo "Waiting for PostgreSQL..."
until docker exec postgres-db pg_isready -U keycloak; do
    sleep 2
done

# Wait for MongoDB
echo "Waiting for MongoDB..."
until docker exec mongo-db mongosh --eval "db.adminCommand('ping')" > /dev/null 2>&1; do
    sleep 2
done

# Wait for Redis
echo "Waiting for Redis..."
until docker exec redis-cache redis-cli -a redis123 ping > /dev/null 2>&1; do
    sleep 2
done

# Wait for Kafka
echo "Waiting for Kafka..."
until docker exec kafka-broker kafka-topics --bootstrap-server localhost:9092 --list > /dev/null 2>&1; do
    sleep 5
done

echo "Infrastructure services are ready!"

# Initialize Kafka topics
echo "Initializing Kafka topics..."
./scripts/init-kafka-topics.sh

# Start Keycloak
echo "Starting Keycloak..."
docker-compose up -d keycloak

# Wait for Keycloak
echo "Waiting for Keycloak to be ready..."
until curl -f http://localhost:8080/health/ready > /dev/null 2>&1; do
    echo "Keycloak is not ready yet. Waiting..."
    sleep 10
done

# Setup Keycloak
echo "Setting up Keycloak realm and users..."
./scripts/setup-keycloak.sh

# Start Kafka UI
echo "Starting Kafka UI..."
docker-compose up -d kafka-ui

# Start application services
echo "Starting application services..."
docker-compose up -d user-service parcel-service tracking-service notification-service location-service chatbot-service eta-service

# Start API Gateway last
echo "Starting API Gateway..."
docker-compose up -d api-gateway

echo "Waiting for all services to be healthy..."
sleep 30

echo "Checking service status..."
docker-compose ps

echo ""
echo "==================================="
echo "LOCAL ENVIRONMENT SETUP COMPLETE!"
echo "==================================="
echo ""
echo "🌐 Service URLs:"
echo "├── API Gateway:      http://localhost:8000"
echo "├── Keycloak Admin:   http://localhost:8080 (admin/admin)"
echo "├── Kafka UI:         http://localhost:8090"
echo "├── MongoDB:          mongodb://admin:admin123@localhost:27017"
echo "└── Redis:            redis://localhost:6379 (password: redis123)"
echo ""
echo "📋 Application Services:"
echo "├── User Service:     http://localhost:8001"
echo "├── Chatbot Service:  http://localhost:8002"
echo "├── Parcel Service:   http://localhost:8003"
echo "├── ETA Service:      http://localhost:8004"
echo "├── Tracking Service: http://localhost:8005"
echo "├── Notification:     http://localhost:8006"
echo "└── Location Service: http://localhost:8007"
echo ""
echo "👥 Test Users:"
echo "├── Admin:     username=admin,     password=admin123"
echo "└── User:      username=testuser,  password=test123"
echo ""
echo "🧪 Test API:"
echo "# Get access token:"
echo 'curl -X POST http://localhost:8080/realms/logistics-realm/protocol/openid-connect/token \'
echo '  -H "Content-Type: application/x-www-form-urlencoded" \'
echo '  -d "username=admin&password=admin123&grant_type=password&client_id=logistics-backend&client_secret=logistics-secret-2024"'
echo ""
echo "# Use token to access protected endpoint:"
echo 'curl -H "Authorization: Bearer <your-token>" http://localhost:8000/api/user/profile'
echo ""
echo "📊 Monitoring:"
echo "├── View logs:        docker-compose logs -f [service-name]"
echo "├── Service status:   docker-compose ps"
echo "└── Stop all:         docker-compose down"