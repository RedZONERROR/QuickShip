#!/bin/bash
# Command Runner Module - Executes shell commands from web interface

parse_and_run_command() {
    local content_length="$1"
    
    # Read POST body
    local body=$(dd bs=1 count="$content_length" 2>/dev/null)
    
    # Parse URL-encoded command
    local command=$(echo "$body" | sed 's/^command=//' | sed 's/+/ /g')
    command=$(printf '%b' "${command//%/\\x}")
    
    if [ -z "$command" ]; then
        echo "{\"success\":false,\"output\":\"No command provided\"}"
        return
    fi
    
    # Execute command and capture output
    local output=$(eval "$command" 2>&1)
    local exit_code=$?
    
    # Escape output for JSON
    output=$(echo "$output" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | awk '{printf "%s\\n", $0}')
    
    if [ $exit_code -eq 0 ]; then
        echo "{\"success\":true,\"output\":\"$output\",\"exit_code\":$exit_code}"
    else
        echo "{\"success\":false,\"output\":\"$output\",\"exit_code\":$exit_code}"
    fi
}
