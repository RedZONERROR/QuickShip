#!/bin/bash
# Request Parser Module - Parses multipart/form-data and extracts files

parse_upload_request() {
    local content_length="$1"
    local boundary="$2"
    
    local temp_file="$TEMP_DIR/upload_$$"
    local filename=""
    local is_executable="false"
    local file_output=""
    
    # Read the body
    dd bs=1 count="$content_length" 2>/dev/null > "$temp_file"
    
    # Parse multipart data
    local current_field=""
    local current_filename=""
    local data_start=false
    
    while IFS= read -r line; do
        line=$(echo "$line" | tr -d '\r')
        
        # Check for boundary
        if echo "$line" | grep -q "^--$boundary"; then
            if [ "$data_start" = true ] && [ -n "$current_filename" ]; then
                # End of file data
                data_start=false
            fi
            current_field=""
            current_filename=""
            continue
        fi
        
        # Parse Content-Disposition header
        if echo "$line" | grep -qi "^Content-Disposition:"; then
            if echo "$line" | grep -q 'name="file"'; then
                current_filename=$(echo "$line" | sed -n 's/.*filename="\([^"]*\)".*/\1/p')
                if [ -z "$current_filename" ]; then
                    current_filename=$(echo "$line" | sed -n "s/.*filename='\([^']*\)'.*/\1/p")
                fi
                filename="$current_filename"
            elif echo "$line" | grep -q 'name="is_executable"'; then
                current_field="is_executable"
            fi
            continue
        fi
        
        # Skip Content-Type header
        if echo "$line" | grep -qi "^Content-Type:"; then
            continue
        fi
        
        # Empty line indicates start of data
        if [ -z "$line" ]; then
            if [ -n "$current_filename" ]; then
                data_start=true
                file_output="$TEMP_DIR/file_$$"
                # Start reading file data on next iteration
                continue
            elif [ "$current_field" = "is_executable" ]; then
                # Next line will have the checkbox value
                read -r value
                value=$(echo "$value" | tr -d '\r')
                if [ "$value" = "on" ] || [ "$value" = "true" ]; then
                    is_executable="true"
                fi
                current_field=""
            fi
            continue
        fi
        
        # Collect file data
        if [ "$data_start" = true ]; then
            if [ -z "$file_output" ]; then
                file_output="$TEMP_DIR/file_$$"
            fi
            echo "$line" >> "$file_output"
        fi
    done < "$temp_file"
    
    # Clean up the file (remove last boundary line)
    if [ -f "$file_output" ]; then
        # Remove trailing boundary markers
        sed -i "/^--$boundary/d" "$file_output" 2>/dev/null || true
        
        # Handle the file
        handle_file "$file_output" "$filename" "$is_executable"
    else
        rm -f "$temp_file"
        echo "{\"success\":false,\"message\":\"No file data received\"}"
        return 1
    fi
    
    rm -f "$temp_file"
}
