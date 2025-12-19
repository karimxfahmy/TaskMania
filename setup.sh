#!/bin/bash

################################################################################
# TaskMania Setup Script
# Automated setup and installation
################################################################################

set -e

echo "======================================"
echo "TaskMania System Monitor Setup"
echo "======================================"
echo ""

# Check for Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed!"
    echo "Please install Docker from: https://docs.docker.com/get-docker/"
    exit 1
fi

echo "✓ Docker found"

# Check for Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed!"
    echo "Please install Docker Compose from: https://docs.docker.com/compose/install/"
    exit 1
fi

echo "✓ Docker Compose found"

# Create necessary directories
echo ""
echo "Creating directories..."
mkdir -p data logs reports
touch data/.gitkeep logs/.gitkeep reports/.gitkeep

# Build containers
echo ""
echo "Building Docker containers..."
docker-compose build

# Start services
echo ""
echo "Starting services..."
docker-compose up -d

echo ""
echo "======================================"
echo "Setup Complete! 🎉"
echo "======================================"
echo ""
echo "Services are now running:"
echo "  📊 Web Dashboard: http://localhost:3000"
echo "  🔌 API Server: http://localhost:8000"
echo "  📈 Grafana: http://localhost:3001"
echo "     Username: admin"
echo "     Password: admin123"
echo ""
echo "Useful commands:"
echo "  • View logs: docker-compose logs -f"
echo "  • Stop services: docker-compose down"
echo "  • Restart services: docker-compose restart"
echo ""
echo "For more information, see README.md"
echo ""
