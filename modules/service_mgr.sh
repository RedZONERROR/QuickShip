#!/bin/bash
# Service Manager Module - Creates and manages systemd services

create_service() {
    local service_name="$1"
    local bin_path="$2"
    
    local service_file="${SERVICE_PREFIX}-${service_name}.service"
    local service_path="$SERVICE_DIR/$service_file"
    
    # Generate systemd service file
    local service_content="[Unit]
Description=QuickShip Service - $service_name
After=network.target

[Service]
Type=simple
ExecStart=$bin_path
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target"
    
    # Write service file
    echo "$service_content" > "$TEMP_DIR/$service_file"
    
    # Move to systemd directory (may need sudo)
    cp "$TEMP_DIR/$service_file" "$service_path" 2>/dev/null || {
        sudo cp "$TEMP_DIR/$service_file" "$service_path"
    }
    
    rm -f "$TEMP_DIR/$service_file"
    
    # Reload systemd and start service
    sudo systemctl daemon-reload
    sudo systemctl enable "$service_file"
    sudo systemctl start "$service_file"
    
    return 0
}

stop_service() {
    local service_name="$1"
    local service_file="${SERVICE_PREFIX}-${service_name}.service"
    
    sudo systemctl stop "$service_file" 2>/dev/null || true
    sudo systemctl disable "$service_file" 2>/dev/null || true
    sudo rm -f "$SERVICE_DIR/$service_file"
    sudo systemctl daemon-reload
}
