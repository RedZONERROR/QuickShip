#!/bin/bash
# Cleanup Module - Remove services and binaries without removing QuickShip

execute_cleanup() {
    local removed_services=0
    local removed_binaries=0
    
    # Stop all QuickShip services
    for service in $(systemctl list-units --all --no-legend 2>/dev/null | grep "^${SERVICE_PREFIX}-" | awk '{print $1}'); do
        echo "Stopping service: $service"
        sudo systemctl stop "$service" 2>/dev/null || true
        sudo systemctl disable "$service" 2>/dev/null || true
        removed_services=$((removed_services + 1))
    done
    
    # Remove service files
    if [ -d "$SERVICE_DIR" ]; then
        for service_file in "$SERVICE_DIR/${SERVICE_PREFIX}-"*.service; do
            if [ -f "$service_file" ]; then
                sudo rm -f "$service_file" 2>/dev/null || true
            fi
        done
    fi
    
    # Remove binaries installed by QuickShip
    if [ -d "$BIN_DIR" ]; then
        # Only remove files that match our service pattern
        for service_file in "$SERVICE_DIR/${SERVICE_PREFIX}-"*.service; do
            if [ -f "$service_file" ]; then
                binary_name=$(basename "$service_file" .service | sed "s/^${SERVICE_PREFIX}-//")
                if [ -f "$BIN_DIR/$binary_name" ]; then
                    sudo rm -f "$BIN_DIR/$binary_name" 2>/dev/null || true
                    removed_binaries=$((removed_binaries + 1))
                fi
            fi
        done
    fi
    
    # Reload systemd
    sudo systemctl daemon-reload 2>/dev/null || true
    
    # Return success message
    echo "{\"success\":true,\"message\":\"Cleanup complete. Removed $removed_services services and $removed_binaries binaries. QuickShip is still running.\"}"
}
