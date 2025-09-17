#!/bin/bash

# Development Test Script for Yapay SDK
# This script runs comprehensive tests in the development container

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

echo -e "${BLUE}Yapay SDK Development Test Suite${NC}"
echo "=================================="

# Function to run docker compose commands
run_compose() {
    if docker compose version > /dev/null 2>&1; then
        docker compose -f "$COMPOSE_FILE" "$@"
    else
        docker-compose -f "$COMPOSE_FILE" "$@"
    fi
}

# Check if container is running
if ! run_compose ps | grep -q "Up"; then
    echo -e "${RED}Error: Development container is not running.${NC}"
    echo -e "${YELLOW}Please run 'make dev-run' first.${NC}"
    exit 1
fi

# Function to run unit tests
run_unit_tests() {
    echo -e "${YELLOW}Running unit tests...${NC}"
    run_compose exec yapay-sdk-dev bash -c "cd /workspace/sdk && go test -v ./..."
    echo -e "${GREEN}Unit tests completed!${NC}"
}

# Function to run integration tests
run_integration_tests() {
    echo -e "${YELLOW}Running integration tests...${NC}"
    
    # Start Yapay server for integration testing
    echo -e "${BLUE}Starting Yapay server for integration testing...${NC}"
    run_compose up -d yapay-server-dev
    
    # Wait for server to be ready
    echo -e "${BLUE}Waiting for Yapay server to be ready...${NC}"
    sleep 15
    
    # Run integration tests
    run_compose exec yapay-sdk-dev bash -c "cd /workspace/sdk && go test -v -tags=integration ./..."
    
    echo -e "${GREEN}Integration tests completed!${NC}"
}

# Function to run plugin tests
run_plugin_tests() {
    echo -e "${YELLOW}Running plugin tests...${NC}"
    
    # Build plugins first
    echo -e "${BLUE}Building plugins...${NC}"
    run_compose exec yapay-sdk-dev bash -c "cd /workspace/sdk && make build"
    
    # Test each plugin
    for plugin_dir in examples/*/; do
        if [ -d "$plugin_dir" ]; then
            plugin_name=$(basename "$plugin_dir")
            echo -e "${BLUE}Testing plugin: $plugin_name${NC}"
            run_compose exec yapay-sdk-dev bash -c "cd /workspace/sdk/examples/$plugin_name && go test -v ./..."
        fi
    done
    
    echo -e "${GREEN}Plugin tests completed!${NC}"
}

# Function to run benchmark tests
run_benchmark_tests() {
    echo -e "${YELLOW}Running benchmark tests...${NC}"
    run_compose exec yapay-sdk-dev bash -c "cd /workspace/sdk && go test -bench=. -benchmem ./..."
    echo -e "${GREEN}Benchmark tests completed!${NC}"
}

# Function to run linting
run_linting() {
    echo -e "${YELLOW}Running linting...${NC}"
    run_compose exec yapay-sdk-dev bash -c "cd /workspace/sdk && make lint"
    echo -e "${GREEN}Linting completed!${NC}"
}

# Function to run security scan
run_security_scan() {
    echo -e "${YELLOW}Running security scan...${NC}"
    run_compose exec yapay-sdk-dev bash -c "cd /workspace/sdk && gosec ./..."
    echo -e "${GREEN}Security scan completed!${NC}"
}

# Function to run code coverage
run_coverage() {
    echo -e "${YELLOW}Running code coverage analysis...${NC}"
    run_compose exec yapay-sdk-dev bash -c "cd /workspace/sdk && go test -coverprofile=coverage.out ./..."
    run_compose exec yapay-sdk-dev bash -c "cd /workspace/sdk && go tool cover -html=coverage.out -o coverage.html"
    echo -e "${GREEN}Code coverage analysis completed!${NC}"
    echo -e "${BLUE}Coverage report saved to coverage.html${NC}"
}

# Function to run all tests
run_all_tests() {
    echo -e "${BLUE}Running comprehensive test suite...${NC}"
    echo ""
    
    run_unit_tests
    echo ""
    
    run_plugin_tests
    echo ""
    
    run_integration_tests
    echo ""
    
    run_benchmark_tests
    echo ""
    
    run_linting
    echo ""
    
    run_security_scan
    echo ""
    
    run_coverage
    echo ""
    
    echo -e "${GREEN}All tests completed successfully! 🎉${NC}"
}

# Function to show test options
show_test_options() {
    echo -e "${BLUE}Test Options:${NC}"
    echo "1. Run unit tests"
    echo "2. Run integration tests"
    echo "3. Run plugin tests"
    echo "4. Run benchmark tests"
    echo "5. Run linting"
    echo "6. Run security scan"
    echo "7. Run code coverage"
    echo "8. Run all tests"
    echo "9. Exit"
    echo ""
}

# Main menu
while true; do
    show_test_options
    read -p "Choose option (1-9): " option
    
    case $option in
        1)
            run_unit_tests
            ;;
        2)
            run_integration_tests
            ;;
        3)
            run_plugin_tests
            ;;
        4)
            run_benchmark_tests
            ;;
        5)
            run_linting
            ;;
        6)
            run_security_scan
            ;;
        7)
            run_coverage
            ;;
        8)
            run_all_tests
            ;;
        9)
            echo -e "${GREEN}Goodbye! 👋${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Please choose 1-9.${NC}"
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
    clear
done
