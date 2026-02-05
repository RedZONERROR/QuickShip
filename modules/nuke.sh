#!/bin/bash
# Nuke Module - Self-destruct functionality

execute_nuke() {
    echo "=========================================="
    echo "  NUKE INITIATED - DESTROYING EVERYTHING"
    echo "=========================================="
    
    # Stop all QuickShip services
    for service in $(systemctl list-units --all --no-legend | grep "^${SERVICE_PREFIX}-" | awk '{print $1}'); do
        echo "Stopping service: $service"
        sudo systemctl stop "$service" 2>/dev/null || true
        sudo systemctl disable "$service" 2>/dev/null || true
    done
    
    # Remove service files
    echo "Removing service files..."
    sudo rm -f "$SERVICE_DIR/${SERVICE_PREFIX}-"*.service 2>/dev/null || true
    
    # Remove binaries
    echo "Removing binaries..."
    for bin in $(ls "$BIN_DIR" 2>/dev/null | grep -v "^$"); do
        # Only remove files that were likely installed by QuickShip
        if [ -f "$BIN_DIR/$bin" ]; then
            sudo rm -f "$BIN_DIR/$bin" 2>/dev/null || true
        fi
    done
    
    # Reload systemd
    sudo systemctl daemon-reload
    
    # Remove QuickShip directory
    echo "Removing QuickShip directory..."
    cd /
    rm -rf "$SCRIPT_DIR"
    
    echo "=========================================="
    echo "  NUKE COMPLETE - GOODBYE"
    echo "=========================================="
    
    exit 0
}
