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

# Always run from workspace root
cd /workspace

# Ensure plugins directory exists but do NOT build plugins in SDK devcontainer
mkdir -p /workspace/plugins
echo -e "${YELLOW}📦 Skipping plugin build in SDK devcontainer. Plugins directory may be empty.${NC}"

# Set up environment variables
export PORT=${PORT:-8080}
export LOG_LEVEL=${LOG_LEVEL:-info}  # info level for SDK development (less noise than debug)
export GIN_MODE=${GIN_MODE:-release}  # release mode for SDK development (less HTTP noise than debug)
export YANDEX_SANDBOX_MODE=${YANDEX_SANDBOX_MODE:-true}
export METRICS_PORT=${METRICS_PORT:-8081}
export METRICS_REQUIRE_AUTH=${METRICS_REQUIRE_AUTH:-false}

echo -e "${BLUE}🔧 Server Configuration:${NC}"
echo -e "  Port: ${PORT}"
echo -e "  Log Level: ${LOG_LEVEL}"
echo -e "  Gin Mode: ${GIN_MODE}"
echo -e "  Sandbox Mode: ${YANDEX_SANDBOX_MODE}"
echo -e "  Metrics Port: ${METRICS_PORT}"
echo -e "  Plugins Directory: /workspace/plugins"

echo -e "${GREEN}🎯 Starting YAPAY Server...${NC}"

# Start the server from the correct location
exec /usr/local/bin/yapay-server
