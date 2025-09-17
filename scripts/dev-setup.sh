#!/bin/bash

# Development Environment Setup Script for Yapay SDK
# This script sets up the development container environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CONTAINER_NAME="yapay-sdk-dev"
COMPOSE_FILE="docker-compose.dev.yml"

echo -e "${BLUE}Yapay SDK Development Environment Setup${NC}"
echo "=============================================="

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}Error: Docker is not running. Please start Docker and try again.${NC}"
    exit 1
fi

# Check if docker-compose is available
if ! command -v docker-compose > /dev/null 2>&1 && ! docker compose version > /dev/null 2>&1; then
    echo -e "${RED}Error: docker-compose is not available. Please install docker-compose.${NC}"
    exit 1
fi

# Function to run docker compose commands
run_compose() {
    if docker compose version > /dev/null 2>&1; then
        docker compose -f "$COMPOSE_FILE" "$@"
    else
        docker-compose -f "$COMPOSE_FILE" "$@"
    fi
}

# Build development container
echo -e "${YELLOW}Building development container...${NC}"
run_compose build

# Start development container
echo -e "${YELLOW}Starting development container...${NC}"
run_compose up -d

# Wait for container to be ready
echo -e "${YELLOW}Waiting for container to be ready...${NC}"
sleep 10

# Check if container is running
if ! run_compose ps | grep -q "Up"; then
    echo -e "${RED}Error: Development container failed to start.${NC}"
    echo -e "${YELLOW}Checking logs...${NC}"
    run_compose logs
    exit 1
fi

# Setup Go modules
echo -e "${YELLOW}Setting up Go modules...${NC}"
run_compose exec yapay-sdk-dev bash -c "cd /workspace/sdk && go mod download && go mod verify"

# Install development tools
echo -e "${YELLOW}Installing development tools...${NC}"
run_compose exec yapay-sdk-dev bash -c "cd /workspace/sdk && make install-deps"

# Run initial tests
echo -e "${YELLOW}Running initial tests...${NC}"
run_compose exec yapay-sdk-dev bash -c "cd /workspace/sdk && make test"

echo -e "${GREEN}Development environment setup completed successfully!${NC}"
echo ""
echo -e "${BLUE}Available commands:${NC}"
echo "  make dev-shell     - Open shell in development container"
echo "  make dev-logs      - Show container logs"
echo "  make dev-status    - Show container status"
echo "  make dev-test      - Run tests in container"
echo "  make dev-debug     - Start debug session"
echo "  make dev-stop      - Stop development container"
echo ""
echo -e "${BLUE}Development URLs:${NC}"
echo "  SDK Development Server: http://localhost:8080"
echo "  Debug Port: 2345"
echo "  Yapay Server (if started): http://localhost:8082"
echo ""
echo -e "${GREEN}Happy coding! 🚀${NC}"
