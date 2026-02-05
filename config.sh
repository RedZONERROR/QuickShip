#!/bin/bash
# QuickShip Configuration

# Server settings
SERVER_HOST="${QUICKSHIP_HOST:-0.0.0.0}"
SERVER_PORT="${QUICKSHIP_PORT:-8080}"

# Paths
UPLOAD_DIR="./uploads"
TEMP_DIR="./temp"
SERVICE_DIR="/etc/systemd/system"
BIN_DIR="/usr/local/bin"

# Service naming
SERVICE_PREFIX="quickship"

# HTTP Response templates
HTTP_200="HTTP/1.1 200 OK"
HTTP_400="HTTP/1.1 400 Bad Request"
HTTP_500="HTTP/1.1 500 Internal Server Error"
