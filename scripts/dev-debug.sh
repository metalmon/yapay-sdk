#!/bin/bash

# Development Debug Script for Yapay SDK
# This script helps with debugging in the development container

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
DEBUG_PORT="2345"

echo -e "${BLUE}Yapay SDK Development Debug Helper${NC}"
echo "====================================="

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

# Function to show debug options
show_debug_options() {
    echo -e "${BLUE}Debug Options:${NC}"
    echo "1. Start debug server (Delve)"
    echo "2. Open shell in container"
    echo "3. Show container logs"
    echo "4. Check container health"
    echo "5. Run tests with debug output"
    echo "6. Profile memory usage"
    echo "7. Profile CPU usage"
    echo "8. Network debugging"
    echo "9. Exit"
    echo ""
}

# Function to start debug server
start_debug_server() {
    echo -e "${YELLOW}Starting debug server on port $DEBUG_PORT...${NC}"
    echo -e "${BLUE}Connect your IDE to localhost:$DEBUG_PORT${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop debug server${NC}"
    echo ""
    
    run_compose exec yapay-sdk-dev bash -c "cd /workspace/sdk && dlv debug --headless --listen=:$DEBUG_PORT --api-version=2"
}

# Function to open shell
open_shell() {
    echo -e "${YELLOW}Opening shell in development container...${NC}"
    run_compose exec yapay-sdk-dev bash
}

# Function to show logs
show_logs() {
    echo -e "${YELLOW}Showing container logs...${NC}"
    run_compose logs -f --tail=50
}

# Function to check health
check_health() {
    echo -e "${YELLOW}Checking container health...${NC}"
    echo -e "${BLUE}Container status:${NC}"
    run_compose ps
    echo ""
    echo -e "${BLUE}Health check:${NC}"
    curl -s http://localhost:8080/health | jq . || echo "Health check failed"
}

# Function to run tests with debug
run_debug_tests() {
    echo -e "${YELLOW}Running tests with debug output...${NC}"
    run_compose exec yapay-sdk-dev bash -c "cd /workspace/sdk && LOG_LEVEL=debug make test"
}

# Function to profile memory
profile_memory() {
    echo -e "${YELLOW}Profiling memory usage...${NC}"
    run_compose exec yapay-sdk-dev bash -c "cd /workspace/sdk && go test -memprofile=mem.prof -bench=. ./..."
    echo -e "${GREEN}Memory profile saved to mem.prof${NC}"
    echo -e "${BLUE}To analyze: go tool pprof mem.prof${NC}"
}

# Function to profile CPU
profile_cpu() {
    echo -e "${YELLOW}Profiling CPU usage...${NC}"
    run_compose exec yapay-sdk-dev bash -c "cd /workspace/sdk && go test -cpuprofile=cpu.prof -bench=. ./..."
    echo -e "${GREEN}CPU profile saved to cpu.prof${NC}"
    echo -e "${BLUE}To analyze: go tool pprof cpu.prof${NC}"
}

# Function to network debugging
network_debug() {
    echo -e "${YELLOW}Network debugging tools...${NC}"
    echo -e "${BLUE}Available network tools:${NC}"
    echo "1. Check listening ports"
    echo "2. Test connectivity to Yapay server"
    echo "3. Monitor network traffic"
    echo "4. Check DNS resolution"
    echo ""
    
    read -p "Choose option (1-4): " network_option
    
    case $network_option in
        1)
            echo -e "${YELLOW}Checking listening ports...${NC}"
            run_compose exec yapay-sdk-dev netstat -tlnp
            ;;
        2)
            echo -e "${YELLOW}Testing connectivity to Yapay server...${NC}"
            run_compose exec yapay-sdk-dev curl -v http://yapay-server-dev:8082/api/v1/health || echo "Connection failed"
            ;;
        3)
            echo -e "${YELLOW}Monitoring network traffic...${NC}"
            echo -e "${BLUE}Press Ctrl+C to stop monitoring${NC}"
            run_compose exec yapay-sdk-dev tcpdump -i any -n
            ;;
        4)
            echo -e "${YELLOW}Checking DNS resolution...${NC}"
            run_compose exec yapay-sdk-dev nslookup yapay-server-dev
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
}

# Main menu
while true; do
    show_debug_options
    read -p "Choose option (1-9): " option
    
    case $option in
        1)
            start_debug_server
            ;;
        2)
            open_shell
            ;;
        3)
            show_logs
            ;;
        4)
            check_health
            ;;
        5)
            run_debug_tests
            ;;
        6)
            profile_memory
            ;;
        7)
            profile_cpu
            ;;
        8)
            network_debug
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
