#!/bin/bash

# CloudPub Tunnel Manager for Yapay SDK Development
# This script manages CloudPub tunnel for external access during SDK development

set -e

CLOUDPUB_BIN="/usr/local/bin/clo"
CLOUDPUB_CONFIG_DIR="$HOME/.cloudpub"
TUNNEL_LOG_FILE="/tmp/cloudpub-tunnel.log"
SERVER_PORT=8080
TUNNEL_NAME="yapay-sdk-dev"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if CloudPub binary exists
check_cloudpub() {
    if [ ! -f "$CLOUDPUB_BIN" ]; then
        error "CloudPub binary not found at $CLOUDPUB_BIN"
        error "Please ensure CloudPub is installed in the development container"
        exit 1
    fi

    if [ ! -x "$CLOUDPUB_BIN" ]; then
        log "Making CloudPub binary executable..."
        chmod +x "$CLOUDPUB_BIN"
    fi
}

# Check if SDK server is running on port 8080
check_server() {
    if ! curl -s "http://localhost:$SERVER_PORT/health" > /dev/null 2>&1; then
        error "SDK development server is not running on port $SERVER_PORT"
        error "Please start the development server first: make dev-run"
        exit 1
    fi
    success "SDK development server is running on port $SERVER_PORT"
}

# Setup CloudPub authentication (if needed)
setup_auth() {
    if [ -z "$CLOUDPUB_TOKEN" ]; then
        warn "CLOUDPUB_TOKEN environment variable not set"
        warn "CloudPub will work without authentication, but with limited features"
        return 0
    fi

    log "Setting up CloudPub authentication..."
    echo "$CLOUDPUB_TOKEN" | "$CLOUDPUB_BIN" login --token-stdin
    success "CloudPub authentication configured"
}

# Start CloudPub tunnel
start_tunnel() {
    log "Starting CloudPub tunnel for SDK development server on port $SERVER_PORT..."

    # Kill any existing tunnel processes
    pkill -f "clo publish http $SERVER_PORT" 2>/dev/null || true

    # Start tunnel in background
    nohup "$CLOUDPUB_BIN" publish http "$SERVER_PORT" > "$TUNNEL_LOG_FILE" 2>&1 &
    TUNNEL_PID=$!

    # Wait a moment for tunnel to establish
    sleep 3

    # Extract tunnel URL from log
    if [ -f "$TUNNEL_LOG_FILE" ]; then
        TUNNEL_URL=$(grep -o "https://[^[:space:]]*\.cloudpub\.ru" "$TUNNEL_LOG_FILE" | tail -1)
        if [ -n "$TUNNEL_URL" ]; then
            success "CloudPub tunnel started successfully!"
            success "Tunnel URL: $TUNNEL_URL"
            success "Tunnel PID: $TUNNEL_PID"

            # Save tunnel info to file for other scripts to use
            echo "$TUNNEL_URL" > /tmp/cloudpub-tunnel-url
            echo "$TUNNEL_PID" > /tmp/cloudpub-tunnel-pid

            # Test tunnel accessibility
            log "Testing tunnel accessibility..."
            if curl -s "$TUNNEL_URL/health" > /dev/null 2>&1; then
                success "Tunnel is accessible from external network!"
                success "SDK API: $TUNNEL_URL/api/v1/"
                success "Health check: $TUNNEL_URL/health"
                return 0
            else
                warn "Tunnel created but not yet accessible (may take a few more seconds)"
            fi
        else
            error "Failed to extract tunnel URL from log"
            return 1
        fi
    else
        error "Tunnel log file not created"
        return 1
    fi
}

# Stop CloudPub tunnel
stop_tunnel() {
    if [ -f "/tmp/cloudpub-tunnel-pid" ]; then
        TUNNEL_PID=$(cat /tmp/cloudpub-tunnel-pid)
        if kill -0 "$TUNNEL_PID" 2>/dev/null; then
            log "Stopping CloudPub tunnel (PID: $TUNNEL_PID)..."
            kill "$TUNNEL_PID"
            success "CloudPub tunnel stopped"
        else
            warn "CloudPub tunnel process not found"
        fi
        rm -f /tmp/cloudpub-tunnel-pid
    fi

    # Clean up any remaining processes
    pkill -f "clo publish http $SERVER_PORT" 2>/dev/null || true
    rm -f /tmp/cloudpub-tunnel-url
}

# Show tunnel status
show_status() {
    if [ -f "/tmp/cloudpub-tunnel-pid" ] && [ -f "/tmp/cloudpub-tunnel-url" ]; then
        TUNNEL_PID=$(cat /tmp/cloudpub-tunnel-pid)
        TUNNEL_URL=$(cat /tmp/cloudpub-tunnel-url)

        if kill -0 "$TUNNEL_PID" 2>/dev/null; then
            success "CloudPub tunnel is running"
            success "Tunnel URL: $TUNNEL_URL"
            success "Tunnel PID: $TUNNEL_PID"
            success "SDK API: $TUNNEL_URL/api/v1/"
            success "Health check: $TUNNEL_URL/health"
        else
            warn "CloudPub tunnel PID file exists but process is not running"
            rm -f /tmp/cloudpub-tunnel-pid /tmp/cloudpub-tunnel-url
        fi
    else
        warn "CloudPub tunnel is not running"
    fi
}

# Main function
main() {
    case "${1:-start}" in
        "start")
            check_cloudpub
            check_server
            setup_auth
            start_tunnel
            ;;
        "stop")
            stop_tunnel
            ;;
        "restart")
            stop_tunnel
            sleep 2
            check_cloudpub
            check_server
            setup_auth
            start_tunnel
            ;;
        "status")
            show_status
            ;;
        "url")
            if [ -f "/tmp/cloudpub-tunnel-url" ]; then
                cat /tmp/cloudpub-tunnel-url
            else
                error "No tunnel URL found"
                exit 1
            fi
            ;;
        *)
            echo "Usage: $0 {start|stop|restart|status|url}"
            echo ""
            echo "Commands:"
            echo "  start   - Start CloudPub tunnel (default)"
            echo "  stop    - Stop CloudPub tunnel"
            echo "  restart - Restart CloudPub tunnel"
            echo "  status  - Show tunnel status"
            echo "  url     - Print tunnel URL"
            echo ""
            echo "Environment variables:"
            echo "  CLOUDPUB_TOKEN - CloudPub authentication token (optional)"
            echo ""
            echo "Examples:"
            echo "  $0 start                    # Start tunnel"
            echo "  $0 status                   # Check status"
            echo "  TUNNEL_URL=\$($0 url)       # Get tunnel URL"
            exit 1
            ;;
    esac
}

main "$@"
