#!/bin/bash

# Fix permissions script for YAPAY SDK development
# This script fixes ownership of files created by root user

echo "🔧 Fixing file permissions..."

# Get current user ID and group ID
USER_ID=$(id -u)
GROUP_ID=$(id -g)

echo "Current user: $(whoami) (UID: $USER_ID, GID: $GROUP_ID)"

# Fix ownership of src directory and its contents
if [ -d "src" ]; then
    echo "Fixing ownership of src/ directory..."
    sudo chown -R $USER_ID:$GROUP_ID src/
    echo "✅ src/ directory ownership fixed"
else
    echo "⚠️ src/ directory not found"
fi

# Fix ownership of plugins directory
if [ -d "plugins" ]; then
    echo "Fixing ownership of plugins/ directory..."
    sudo chown -R $USER_ID:$GROUP_ID plugins/
    echo "✅ plugins/ directory ownership fixed"
else
    echo "⚠️ plugins/ directory not found"
fi

# Fix ownership of tools directory
if [ -d "tools" ]; then
    echo "Fixing ownership of tools/ directory..."
    sudo chown -R $USER_ID:$GROUP_ID tools/
    echo "✅ tools/ directory ownership fixed"
else
    echo "⚠️ tools/ directory not found"
fi

echo "🎉 Permission fix completed!"
echo ""
echo "Now you can:"
echo "  make new-plugin-my-plugin-name"
echo "  make build-plugin-my-plugin-name"
echo "  make test-plugins"
