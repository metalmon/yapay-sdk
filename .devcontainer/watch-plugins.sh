#!/bin/bash

# Plugin Hot-Reload Watcher Script
# This script watches for changes in plugin source code and rebuilds them automatically

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}👀 Starting Plugin Hot-Reload Watcher${NC}"

# Check if we're in the right directory
if [ ! -d "/workspace/src" ]; then
    echo -e "${RED}❌ Error: src directory not found. Please run this from the workspace root.${NC}"
    exit 1
fi

# Check if inotify-tools is available
if ! command -v inotifywait &> /dev/null; then
    echo -e "${YELLOW}⚠️  inotify-tools not found. Installing...${NC}"
    apk add --no-cache inotify-tools
fi

# Function to rebuild a plugin
rebuild_plugin() {
    local plugin_name=$1
    
    echo -e "${YELLOW}🔄 Rebuilding plugin: $plugin_name${NC}"
    
    # Use Makefile command for consistent build
    cd /workspace
    if make "build-plugin-$plugin_name"; then
        echo -e "${GREEN}✅ Plugin $plugin_name rebuilt successfully${NC}"
    else
        echo -e "${RED}❌ Failed to rebuild plugin: $plugin_name${NC}"
        return 1
    fi
}

# Function to rebuild all plugins
rebuild_all_plugins() {
    echo -e "${BLUE}📦 Rebuilding all plugins...${NC}"
    cd /workspace
    make build-plugins
    echo -e "${GREEN}✅ All plugins rebuilt${NC}"
}

# Initial build
rebuild_all_plugins

echo -e "${GREEN}🎯 Watching for changes in plugin source code...${NC}"
echo -e "${BLUE}Press Ctrl+C to stop${NC}"

# Watch for changes in plugin source files
inotifywait -m -r -e modify,create,delete /workspace/src/ --format '%w%f %e' | while read file event; do
    # Extract plugin name from file path
    plugin_name=$(echo "$file" | sed 's|/workspace/src/||' | cut -d'/' -f1)
    
    # Skip if it's not a plugin directory
    if [ ! -d "/workspace/src/$plugin_name" ]; then
        continue
    fi
    
    # Skip if it's not a Go file or config file
    if [[ ! "$file" =~ \.(go|yaml|yml)$ ]]; then
        continue
    fi
    
    echo -e "${YELLOW}📝 Change detected in: $file ($event)${NC}"
    
    # Rebuild the specific plugin (server will auto-detect changes)
    rebuild_plugin "$plugin_name"
done
