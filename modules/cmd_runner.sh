#!/bin/bash
# Command Runner Module - Executes shell commands from web interface

parse_and_run_command() {
    local content_length="$1"
    
    # Read POST body
    local body
    body=$(dd bs=1 count="$content_length" 2>/dev/null)
    
    # Parse URL-encoded command
    local command
    command=$(echo "$body" | sed 's/^command=//' | sed 's/+/ /g')
    command=$(printf '%b' "${command//%/\\x}")
    
    if [ -z "$command" ]; then
        echo '{"success":false,"output":"No command provided"}'
        return
    fi
    
    # Execute command and capture output
    local output
    local exit_code
    
    # Run command in a subshell with timeout
    output=$(timeout 30 bash -c "$command" 2>&1)
    exit_code=$?
    
    # Handle empty output
    if [ -z "$output" ]; then
        output="Command executed successfully (no output)"
    fi
    
    # Escape output for JSON properly
    # Replace backslash, quotes, newlines, tabs, carriage returns
    output=$(echo "$output" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g' | sed 's/\t/\\t/g' | sed 's/\r/\\r/g')
    
    # Build JSON response
    if [ $exit_code -eq 0 ]; then
        echo "{\"success\":true,\"output\":\"$output\",\"exit_code\":$exit_code}"
    else
        echo "{\"success\":false,\"output\":\"$output\",\"exit_code\":$exit_code}"
    fi
}
