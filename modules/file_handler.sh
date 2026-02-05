#!/bin/bash
# File Handler Module - Saves or installs files based on executable flag

handle_file() {
    local temp_file="$1"
    local filename="$2"
    local is_executable="$3"
    
    if [ -z "$filename" ]; then
        filename="uploaded_file_$(date +%s)"
    fi
    
    # Sanitize filename
    filename=$(echo "$filename" | sed 's/[^a-zA-Z0-9._-]/_/g')
    
    if [ "$is_executable" = "true" ]; then
        # Install as service
        local bin_path="$BIN_DIR/$filename"
        
        # Copy to bin directory
        cp "$temp_file" "$bin_path" 2>/dev/null || {
            sudo cp "$temp_file" "$bin_path"
        }
        
        # Make executable
        chmod +x "$bin_path" 2>/dev/null || sudo chmod +x "$bin_path"
        
        # Create and start service
        create_service "$filename" "$bin_path"
        
        rm -f "$temp_file"
        
        echo "{\"success\":true,\"message\":\"File installed as service: $filename\",\"path\":\"$bin_path\",\"service\":\"${SERVICE_PREFIX}-${filename}.service\"}"
    else
        # Just save to uploads directory
        local upload_path="$UPLOAD_DIR/$filename"
        mv "$temp_file" "$upload_path"
        
        echo "{\"success\":true,\"message\":\"File uploaded successfully\",\"path\":\"$upload_path\"}"
    fi
}
