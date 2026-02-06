#!/bin/bash
# QuickShip Deployment Toolkit - Main Entry Point
# Zero dependencies - Pure bash + netcat

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Load configuration
source ./config.sh

# Load all modules
source ./modules/http_server.sh
source ./modules/req_parser.sh
source ./modules/file_handler.sh
source ./modules/cmd_runner.sh
source ./modules/service_mgr.sh
source ./modules/cleanup.sh
source ./modules/nuke.sh

# Create necessary directories
mkdir -p "$UPLOAD_DIR"
mkdir -p "$TEMP_DIR"
mkdir -p views

echo "=========================================="
echo "  QuickShip Deployment Toolkit"
echo "=========================================="
echo "Server starting on $SERVER_HOST:$SERVER_PORT"
echo "Access dashboard at: http://$SERVER_HOST:$SERVER_PORT/"
echo "Press Ctrl+C to stop"
echo "=========================================="

# Start the HTTP server
start_http_server
