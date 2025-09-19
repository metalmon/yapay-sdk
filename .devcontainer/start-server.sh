#!/bin/bash

# YAPAY Server Startup Script for Development
# This script starts the YAPAY server with proper configuration for plugin development

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting YAPAY Server for Development${NC}"

# Check if we're in the right directory
if [ ! -d "/workspace/plugins" ]; then
    echo -e "${RED}❌ Error: plugins directory not found. Please run this from the workspace root.${NC}"
    exit 1
fi

# Build plugins first
echo -e "${YELLOW}📦 Building plugins...${NC}"
cd /workspace
make build-examples

# Check if plugins were built successfully
if [ ! -f "/workspace/plugins/simple-plugin/simple-plugin.so" ]; then
    echo -e "${RED}❌ Error: Failed to build plugins. Please check the build output.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Plugins built successfully${NC}"

# Set up environment variables
export PORT=${PORT:-8080}
export LOG_LEVEL=${LOG_LEVEL:-debug}
export GIN_MODE=${GIN_MODE:-debug}
export YANDEX_SANDBOX_MODE=${YANDEX_SANDBOX_MODE:-true}
export METRICS_PORT=${METRICS_PORT:-8081}
export METRICS_REQUIRE_AUTH=${METRICS_REQUIRE_AUTH:-false}

# Create plugins directory if it doesn't exist
mkdir -p /workspace/plugins

echo -e "${BLUE}🔧 Server Configuration:${NC}"
echo -e "  Port: ${PORT}"
echo -e "  Log Level: ${LOG_LEVEL}"
echo -e "  Gin Mode: ${GIN_MODE}"
echo -e "  Sandbox Mode: ${YANDEX_SANDBOX_MODE}"
echo -e "  Metrics Port: ${METRICS_PORT}"
echo -e "  Plugins Directory: /workspace/plugins"

echo -e "${GREEN}🎯 Starting YAPAY Server...${NC}"

# Start the server
exec /usr/local/bin/yapay
