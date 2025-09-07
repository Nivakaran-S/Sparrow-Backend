#!/bin/bash

echo "Waiting for Kafka to be ready..."

# Wait for Kafka to be ready
until docker exec kafka-broker kafka-topics --bootstrap-server localhost:9092 --list > /dev/null 2>&1; do
    echo "Kafka is not ready yet. Waiting..."
    sleep 5
done

echo "Kafka is ready! Creating topics..."

# Create Kafka topics
TOPICS=(
    "user-events"
    "parcel-events" 
    "tracking-events"
    "notification-events"
    "location-events"
    "chatbot-events"
    "eta-events"
    "audit-events"
    "system-events"
)

for topic in "${TOPICS[@]}"; do
    echo "Creating topic: $topic"
    docker exec kafka-broker kafka-topics \
        --create \
        --bootstrap-server localhost:9092 \
        --topic $topic \
        --partitions 3 \
        --replication-factor 1 \
        --config retention.ms=604800000 \
        --config cleanup.policy=delete \
        --if-not-exists
done

echo "Listing all topics:"
docker exec kafka-broker kafka-topics --bootstrap-server localhost:9092 --list

echo "Kafka topics created successfully!"

# Test producer and consumer (optional)
echo "Testing Kafka with a test message..."
echo "test-message-$(date)" | docker exec -i kafka-broker kafka-console-producer \
    --bootstrap-server localhost:9092 \
    --topic user-events

echo "Kafka setup completed successfully!"
echo "You can access Kafka UI at: http://localhost:8090"