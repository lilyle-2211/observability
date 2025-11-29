#!/bin/bash

# Prometheus & Grafana Setup Script
set -e

echo "Setting up Prometheus and Grafana..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "ERROR: Docker is not running. Please start Docker first."
    exit 1
fi

# Check if Docker Compose is available
if ! command -v docker-compose &> /dev/null; then
    echo "ERROR: Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Stop any existing containers
echo "Stopping any existing containers..."
cd docker
docker-compose down 2>/dev/null || echo "No existing containers to stop"
cd ..

# Check if ports are available
echo "Checking port availability..."
ports=(3000 9090)
for port in "${ports[@]}"; do
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null; then
        echo "WARNING: Port $port is already in use. Please stop the service using this port."
        echo "   You can find the process with: lsof -i :$port"
        exit 1
    fi
done

# Pull Docker images
echo "Pulling Docker images..."
cd docker
docker-compose pull

# Start the services
echo "Starting Docker containers..."
docker-compose up -d

# Wait for services to be ready
echo "Waiting for services to start..."
sleep 10

# Check service health
echo "Checking service health..."

# Check Prometheus
if curl -s http://localhost:9090/-/ready > /dev/null; then
    echo "✓ Prometheus is ready"
else
    echo "✗ Prometheus is not ready yet"
fi

# Check Grafana
if curl -s http://localhost:3000/api/health > /dev/null; then
    echo "✓ Grafana is ready"
else
    echo "✗ Grafana is not ready yet"
fi

echo ""
echo "Setup complete!"
echo ""
echo "Access your services:"
echo "  Grafana:    http://localhost:3000 (admin/admin)"
echo "  Prometheus: http://localhost:9090"
echo ""
echo "To stop: cd docker && docker-compose down"
echo "To view logs: cd docker && docker-compose logs -f"