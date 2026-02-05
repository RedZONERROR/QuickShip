#!/bin/bash
# QuickShip Configuration

# Server settings
export SERVER_HOST="${QUICKSHIP_HOST:-0.0.0.0}"
export SERVER_PORT="${QUICKSHIP_PORT:-8080}"

# Paths
export UPLOAD_DIR="./uploads"
export TEMP_DIR="./temp"
export SERVICE_DIR="/etc/systemd/system"
export BIN_DIR="/usr/local/bin"

# Service naming
export SERVICE_PREFIX="quickship"

# HTTP Response templates
export HTTP_200="HTTP/1.1 200 OK"
export HTTP_400="HTTP/1.1 400 Bad Request"
export HTTP_500="HTTP/1.1 500 Internal Server Error"
