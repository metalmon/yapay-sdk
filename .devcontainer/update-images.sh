#!/bin/bash

# Script to update Docker images for YAPAY SDK development
echo "🔄 Updating Docker images for YAPAY SDK development..."

# Check if Docker is available
if ! command -v docker >/dev/null 2>&1; then
    echo "❌ Docker is not available"
    exit 1
fi

# Update images
echo "📦 Pulling latest images..."
docker pull metalmon/yapay:builder
docker pull metalmon/yapay:dev

echo "✅ Docker images updated successfully!"
echo ""
echo "Available images:"
docker images | grep metalmon/yapay
