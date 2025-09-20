#!/bin/bash

# Update Development Docker Image Script
# This script pulls the latest development image from DockerHub

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔄 Updating YAPAY SDK Development Image${NC}"
echo "=============================================="

# Configuration
DEV_IMAGE="metalmon/yapay:dev"
COMPOSE_FILE=".devcontainer/docker-compose.yml"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Error: Docker is not running. Please start Docker and try again.${NC}"
    exit 1
fi

# Check if we're in the right directory
if [ ! -f "$COMPOSE_FILE" ]; then
    echo -e "${RED}❌ Error: docker-compose.yml not found. Please run this from the yapay-sdk root directory.${NC}"
    exit 1
fi

echo -e "${YELLOW}📥 Pulling latest development image...${NC}"
if docker pull "$DEV_IMAGE"; then
    echo -e "${GREEN}✅ Development image updated successfully!${NC}"
else
    echo -e "${RED}❌ Failed to pull development image.${NC}"
    echo -e "${YELLOW}This might mean:${NC}"
    echo -e "${YELLOW}  1. The dev image hasn't been built yet in the yapay project${NC}"
    echo -e "${YELLOW}  2. Network connectivity issues${NC}"
    echo -e "${YELLOW}  3. DockerHub authentication issues${NC}"
    echo ""
    echo -e "${YELLOW}You can still use the local build fallback.${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}🔍 Checking image details...${NC}"
docker images "$DEV_IMAGE" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"

echo ""
echo -e "${GREEN}🎯 Next steps:${NC}"
echo -e "${GREEN}  1. Stop existing development container:${NC}"
echo -e "${GREEN}     docker-compose -f $COMPOSE_FILE down${NC}"
echo ""
echo -e "${GREEN}  2. Start updated development container:${NC}"
echo -e "${GREEN}     docker-compose -f $COMPOSE_FILE up -d${NC}"
echo ""
echo -e "${GREEN}  3. Connect to the container:${NC}"
echo -e "${GREEN}     docker exec -it yapay-sdk_devcontainer-yapay-sdk-development-1 bash${NC}"

echo ""
echo -e "${BLUE}💡 Tip: The development image is automatically updated weekly via GitHub Actions.${NC}"
echo -e "${BLUE}   You can also trigger a manual update in the yapay project repository.${NC}"
