#!/usr/bin/env perl
use strict;
use warnings;
use IO::Socket::INET;
use File::Basename;
use Cwd 'abs_path';

# Configuration
my $PORT = 8888;
my $UPLOAD_DIR = 'uploads';
my $current_filename = '';

# Get script location for self-destruct
my $SCRIPT_PATH = abs_path($0);
my $SCRIPT_DIR = dirname($SCRIPT_PATH);

print "Starting Disposable Deployment Server on port $PORT...\n";
print "Access at: http://YOUR_VPS_IP:$PORT\n";
print "Script location: $SCRIPT_PATH\n";
print "Working directory: $SCRIPT_DIR\n";
print "Upload directory: $UPLOAD_DIR\n\n";

# Create upload directory if it doesn't exist
mkdir $UPLOAD_DIR unless -d $UPLOAD_DIR;

# Create socket
my $socket = IO::Socket::INET->new(
    LocalPort => $PORT,
    Listen    => 5,
    Reuse     => 1,
    Proto     => 'tcp',
) or die "Cannot create socket: $!\n";

print "Server ready. Waiting for connections...\n";

# Main server loop
while (my $client = $socket->accept()) {
    my $request = '';
    my $line;
    
    # Read request headers
    while (defined($line = <$client>) && $line !~ /^\r?\n$/) {
        $request .= $line;
    }
    
    # Parse request
    my ($method, $path) = $request =~ /^(\w+)\s+(\S+)/;
    
    if ($method eq 'GET' && $path eq '/') {
        serve_html($client);
    }
    elsif ($method eq 'POST' && $path eq '/upload') {
        handle_upload($client, $request);
    }
    elsif ($method eq 'POST' && $path eq '/exec') {
        handle_command($client, $request);
    }
    elsif ($method eq 'POST' && $path eq '/destroy') {
        handle_self_destruct($client, $request);
    }
    else {
        send_404($client);
    }
    
    close($client);
}

close($socket);

# Serve HTML upload form
sub serve_html {
    my ($client) = @_;
    
    my $html = <<'HTML';
<!DOCTYPE html>
<html>
<head>
    <title>Disposable Deployment</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 600px;
            margin: 50px auto;
            padding: 20px;
            background: #f5f5f5;
        }
        .container {
            background: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 {
            color: #333;
            margin-top: 0;
        }
        h1 i {
            margin-right: 10px;
            color: #007bff;
        }
        .warning {
            background: #fff3cd;
            border: 1px solid #ffc107;
            padding: 10px;
            border-radius: 4px;
            margin: 15px 0;
            color: #856404;
        }
        .warning i {
            margin-right: 8px;
        }
        input[type="file"] {
            margin: 20px 0;
            padding: 10px;
            border: 2px dashed #ddd;
            width: 100%;
            box-sizing: border-box;
        }
        button {
            background: #007bff;
            color: white;
            border: none;
            padding: 12px 30px;
            font-size: 16px;
            border-radius: 4px;
            cursor: pointer;
            width: 100%;
        }
        button:hover {
            background: #0056b3;
        }
        #status {
            margin-top: 20px;
            padding: 10px;
            border-radius: 4px;
            display: none;
        }
        .success {
            background: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
        }
        .error {
            background: #f8d7da;
            color: #721c24;
            border: 1px solid #f5c6cb;
        }
        .progress-container {
            margin-top: 20px;
            display: none;
        }
        .progress-bar {
            width: 100%;
            height: 30px;
            background: #e9ecef;
            border-radius: 4px;
            overflow: hidden;
            position: relative;
        }
        .progress-fill {
            height: 100%;
            background: linear-gradient(90deg, #007bff, #0056b3);
            width: 0%;
            transition: width 0.3s ease;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .progress-text {
            position: absolute;
            width: 100%;
            text-align: center;
            line-height: 30px;
            font-weight: bold;
            color: #333;
            z-index: 1;
        }
        .terminal-btn {
            margin-top: 20px;
            text-align: center;
        }
        .terminal-btn button {
            background: #28a745;
            width: auto;
            padding: 10px 20px;
        }
        .terminal-btn button:hover {
            background: #218838;
        }
        .terminal-btn i {
            margin-right: 8px;
        }
        .destroy-btn {
            margin-top: 10px;
            text-align: center;
        }
        .destroy-btn button {
            background: #dc3545;
            width: auto;
            padding: 10px 20px;
        }
        .destroy-btn button:hover {
            background: #c82333;
        }
        .destroy-btn i {
            margin-right: 8px;
        }
        
        /* Modal Styles */
        .modal {
            display: none;
            position: fixed;
            z-index: 1000;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            background-color: rgba(0,0,0,0.7);
        }
        .modal-content {
            background-color: #1e1e1e;
            margin: 2% auto;
            width: 90%;
            height: 90%;
            border-radius: 8px;
            display: flex;
            flex-direction: column;
            box-shadow: 0 4px 20px rgba(0,0,0,0.5);
        }
        .modal-header {
            background: #2d2d30;
            padding: 15px 20px;
            border-bottom: 1px solid #3e3e42;
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-radius: 8px 8px 0 0;
        }
        .modal-header h2 {
            font-size: 18px;
            color: #cccccc;
            margin: 0;
        }
        .modal-header i {
            margin-right: 10px;
            color: #4ec9b0;
        }
        .close {
            color: #aaa;
            font-size: 28px;
            font-weight: bold;
            cursor: pointer;
            line-height: 20px;
        }
        .close:hover,
        .close:focus {
            color: #fff;
        }
        .terminal-container {
            flex: 1;
            display: flex;
            flex-direction: column;
            padding: 20px;
            overflow: hidden;
        }
        #output {
            flex: 1;
            overflow-y: auto;
            margin-bottom: 10px;
            padding: 10px;
            background: #1e1e1e;
            border: 1px solid #3e3e42;
            border-radius: 4px;
            font-size: 14px;
            line-height: 1.5;
            font-family: 'Courier New', monospace;
            color: #d4d4d4;
        }
        .output-line {
            margin: 2px 0;
            white-space: pre-wrap;
            word-wrap: break-word;
        }
        .command-line {
            color: #4ec9b0;
        }
        .error-line {
            color: #f48771;
        }
        .success-line {
            color: #89d185;
        }
        .input-container {
            display: flex;
            gap: 10px;
            align-items: center;
        }
        .prompt {
            color: #4ec9b0;
            font-weight: bold;
            font-family: 'Courier New', monospace;
        }
        #commandInput {
            flex: 1;
            background: #2d2d30;
            border: 1px solid #3e3e42;
            color: #d4d4d4;
            padding: 10px;
            font-family: 'Courier New', monospace;
            font-size: 14px;
            border-radius: 4px;
        }
        #commandInput:focus {
            outline: none;
            border-color: #007acc;
        }
        .terminal-container button {
            background: #0e639c;
            color: white;
            border: none;
            padding: 10px 20px;
            font-size: 14px;
            border-radius: 4px;
            cursor: pointer;
            font-family: 'Courier New', monospace;
            width: auto;
        }
        .terminal-container button:hover {
            background: #1177bb;
        }
        .terminal-container button:disabled {
            background: #3e3e42;
            cursor: not-allowed;
        }
        .info {
            background: #1e3a5f;
            padding: 10px;
            border-radius: 4px;
            margin-bottom: 10px;
            font-size: 12px;
            border-left: 3px solid #007acc;
            color: #d4d4d4;
        }
        .info i {
            margin-right: 8px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1><i class="fas fa-rocket"></i>Disposable Deployment</h1>
        <div class="warning">
            <i class="fas fa-exclamation-triangle"></i><strong>Warning:</strong> Use self-destruct button to remove the server when done.
        </div>
        <form id="uploadForm" enctype="multipart/form-data">
            <label for="file"><strong>Select executable file:</strong></label>
            <input type="file" id="file" name="file" required>
            
            <div style="margin: 15px 0; padding: 10px; background: #f8f9fa; border-radius: 4px;">
                <label style="display: flex; align-items: center; cursor: pointer; margin-bottom: 10px;">
                    <input type="checkbox" id="executeCheckbox" name="execute" checked style="margin-right: 10px; width: 18px; height: 18px; cursor: pointer;">
                    <span><strong>Execute as application (runs in background)</strong></span>
                </label>
                <small style="display: block; margin-bottom: 10px; color: #6c757d; margin-left: 28px;">
                    Uncheck to upload file without execution
                </small>
                
                <label style="display: flex; align-items: center; cursor: pointer;">
                    <input type="checkbox" id="serviceCheckbox" name="service" style="margin-right: 10px; width: 18px; height: 18px; cursor: pointer;">
                    <span><strong>Install as systemd service (persistent)</strong></span>
                </label>
                <small style="display: block; color: #6c757d; margin-left: 28px;">
                    Auto-start on reboot, auto-restart on crash
                </small>
            </div>
            
            <button type="submit"><i class="fas fa-upload"></i> <span id="btnText">Deploy & Self-Destruct</span></button>
        </form>
        <div class="terminal-btn">
            <button id="openTerminal"><i class="fas fa-terminal"></i>Open Terminal</button>
        </div>
        <div class="destroy-btn">
            <button id="selfDestruct"><i class="fas fa-bomb"></i>Self-Destruct Server</button>
        </div>
        <div class="progress-container" id="progressContainer">
            <div class="progress-bar">
                <div class="progress-text" id="progressText">0%</div>
                <div class="progress-fill" id="progressFill"></div>
            </div>
        </div>
        <div id="status"></div>
    </div>
    
    <!-- Terminal Modal -->
    <div id="terminalModal" class="modal">
        <div class="modal-content">
            <div class="modal-header">
                <h2><i class="fas fa-terminal"></i>QuickShip Terminal</h2>
                <span class="close">&times;</span>
            </div>
            <div class="terminal-container">
                <div class="info">
                    <i class="fas fa-exclamation-circle"></i>Warning: All commands run with full system access. No security restrictions.
                </div>
                <div id="output"></div>
                <div class="input-container">
                    <span class="prompt">$</span>
                    <input type="text" id="commandInput" placeholder="Enter command...">
                    <button id="execBtn"><i class="fas fa-play"></i> Execute</button>
                    <button id="clearBtn"><i class="fas fa-eraser"></i> Clear</button>
                </div>
            </div>
        </div>
    </div>
    
    <script>
        const modal = document.getElementById('terminalModal');
        const openTerminalBtn = document.getElementById('openTerminal');
        const closeBtn = document.getElementsByClassName('close')[0];
        const output = document.getElementById('output');
        const commandInput = document.getElementById('commandInput');
        const execBtn = document.getElementById('execBtn');
        const clearBtn = document.getElementById('clearBtn');
        
        let commandHistory = [];
        let historyIndex = -1;
        
        // Modal controls
        openTerminalBtn.onclick = function() {
            modal.style.display = 'block';
            commandInput.focus();
        }
        
        closeBtn.onclick = function() {
            modal.style.display = 'none';
        }
        
        window.onclick = function(event) {
            if (event.target == modal) {
                modal.style.display = 'none';
            }
        }
        
        // Terminal functions
        function addOutput(text, className = '') {
            const line = document.createElement('div');
            line.className = 'output-line ' + className;
            line.textContent = text;
            output.appendChild(line);
            output.scrollTop = output.scrollHeight;
        }
        
        function executeCommand() {
            const command = commandInput.value.trim();
            if (!command) return;
            
            commandHistory.push(command);
            historyIndex = commandHistory.length;
            
            addOutput('$ ' + command, 'command-line');
            
            execBtn.disabled = true;
            commandInput.disabled = true;
            
            fetch('/exec', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                },
                body: 'command=' + encodeURIComponent(command)
            })
            .then(response => response.text())
            .then(result => {
                if (result.trim()) {
                    const lines = result.split('\n');
                    lines.forEach(line => {
                        if (line.trim()) {
                            addOutput(line);
                        }
                    });
                } else {
                    addOutput('(no output)', 'success-line');
                }
            })
            .catch(error => {
                addOutput('Error: ' + error.message, 'error-line');
            })
            .finally(() => {
                execBtn.disabled = false;
                commandInput.disabled = false;
                commandInput.value = '';
                commandInput.focus();
            });
        }
        
        execBtn.addEventListener('click', executeCommand);
        
        commandInput.addEventListener('keydown', (e) => {
            if (e.key === 'Enter') {
                executeCommand();
            } else if (e.key === 'ArrowUp') {
                e.preventDefault();
                if (historyIndex > 0) {
                    historyIndex--;
                    commandInput.value = commandHistory[historyIndex];
                }
            } else if (e.key === 'ArrowDown') {
                e.preventDefault();
                if (historyIndex < commandHistory.length - 1) {
                    historyIndex++;
                    commandInput.value = commandHistory[historyIndex];
                } else {
                    historyIndex = commandHistory.length;
                    commandInput.value = '';
                }
            }
        });
        
        clearBtn.addEventListener('click', () => {
            output.innerHTML = '';
            commandInput.value = '';
            commandInput.focus();
        });
        
        // Upload form handling
        const executeCheckbox = document.getElementById('executeCheckbox');
        const btnText = document.getElementById('btnText');
        const selfDestructBtn = document.getElementById('selfDestruct');
        
        // Self-destruct button handler
        selfDestructBtn.addEventListener('click', function() {
            const shouldExecute = executeCheckbox.checked;
            const installService = document.getElementById('serviceCheckbox').checked;
            
            let confirmMsg = 'Are you sure you want to self-destruct the server? This will delete run.pl and stop the server.';
            if (shouldExecute && installService) {
                confirmMsg = 'Install uploaded file as systemd service and self-destruct? The service will run persistently.';
            } else if (shouldExecute) {
                confirmMsg = 'Execute the uploaded file in background and self-destruct the server?';
            }
            
            if (confirm(confirmMsg)) {
                this.disabled = true;
                this.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Self-Destructing...';
                
                fetch('/destroy', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/x-www-form-urlencoded',
                    },
                    body: 'execute=' + (shouldExecute ? '1' : '0') + '&service=' + (installService ? '1' : '0')
                })
                .then(response => response.text())
                .then(result => {
                    alert(result);
                    const msg = shouldExecute 
                        ? '<p>The uploaded file is running and run.pl has been deleted.</p>'
                        : '<p>The server has been stopped and run.pl has been deleted.</p>';
                    document.body.innerHTML = '<div style="text-align: center; padding: 50px; font-family: Arial;"><h1><i class="fas fa-check-circle" style="color: #28a745;"></i></h1><h2>Server Self-Destructed</h2>' + msg + '</div>';
                })
                .catch(error => {
                    const msg = shouldExecute 
                        ? 'Self-destruct initiated. File running and server is shutting down.'
                        : 'Self-destruct initiated. Server is shutting down.';
                    alert(msg);
                    document.body.innerHTML = '<div style="text-align: center; padding: 50px; font-family: Arial;"><h1><i class="fas fa-check-circle" style="color: #28a745;"></i></h1><h2>Server Self-Destructed</h2></div>';
                });
            }
        });
        
        // Update button text based on checkbox
        executeCheckbox.addEventListener('change', function() {
            if (this.checked) {
                btnText.textContent = 'Upload & Execute';
            } else {
                btnText.textContent = 'Upload File';
            }
        });
        
        // Update button text on page load
        btnText.textContent = 'Upload & Execute';
        
        document.getElementById('uploadForm').addEventListener('submit', async (e) => {
            e.preventDefault();
            
            const fileInput = document.getElementById('file');
            const statusDiv = document.getElementById('status');
            const button = e.target.querySelector('button');
            const progressContainer = document.getElementById('progressContainer');
            const progressFill = document.getElementById('progressFill');
            const progressText = document.getElementById('progressText');
            const shouldExecute = executeCheckbox.checked;
            
            if (!fileInput.files[0]) {
                statusDiv.className = 'error';
                statusDiv.innerHTML = '<i class="fas fa-exclamation-circle"></i> Please select a file';
                statusDiv.style.display = 'block';
                return;
            }
            
            button.disabled = true;
            button.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Uploading...';
            statusDiv.style.display = 'none';
            progressContainer.style.display = 'block';
            progressFill.style.width = '0%';
            progressText.textContent = '0%';
            
            const formData = new FormData();
            formData.append('file', fileInput.files[0]);
            formData.append('execute', shouldExecute ? '1' : '0');
            formData.append('service', document.getElementById('serviceCheckbox').checked ? '1' : '0');
            
            try {
                const xhr = new XMLHttpRequest();
                
                // Track upload progress
                xhr.upload.addEventListener('progress', (e) => {
                    if (e.lengthComputable) {
                        const percentComplete = Math.round((e.loaded / e.total) * 100);
                        progressFill.style.width = percentComplete + '%';
                        progressText.textContent = percentComplete + '%';
                        
                        if (percentComplete === 100) {
                            button.innerHTML = '<i class="fas fa-cog fa-spin"></i> Processing...';
                        }
                    }
                });
                
                // Handle completion
                xhr.addEventListener('load', () => {
                    progressContainer.style.display = 'none';
                    
                    if (xhr.status === 200) {
                        statusDiv.className = 'success';
                        statusDiv.innerHTML = '<i class="fas fa-check-circle"></i> ' + xhr.responseText;
                        statusDiv.style.display = 'block';
                        
                        if (shouldExecute && document.getElementById('serviceCheckbox').checked) {
                            button.innerHTML = '<i class="fas fa-check"></i> Service Installed!';
                        } else if (shouldExecute) {
                            button.innerHTML = '<i class="fas fa-check"></i> Uploaded & Executing!';
                        } else {
                            button.innerHTML = '<i class="fas fa-check"></i> Uploaded!';
                        }
                    } else {
                        statusDiv.className = 'error';
                        statusDiv.innerHTML = '<i class="fas fa-times-circle"></i> ' + xhr.responseText;
                        statusDiv.style.display = 'block';
                        button.disabled = false;
                        button.innerHTML = '<i class="fas fa-upload"></i> ' + btnText.textContent;
                    }
                });
                
                // Handle errors
                xhr.addEventListener('error', () => {
                    progressContainer.style.display = 'none';
                    statusDiv.className = 'error';
                    statusDiv.innerHTML = '<i class="fas fa-times-circle"></i> Upload failed: Network error';
                    statusDiv.style.display = 'block';
                    button.disabled = false;
                    button.innerHTML = '<i class="fas fa-upload"></i> ' + btnText.textContent;
                });
                
                xhr.open('POST', '/upload');
                xhr.send(formData);
                
            } catch (error) {
                progressContainer.style.display = 'none';
                statusDiv.className = 'error';
                statusDiv.innerHTML = '<i class="fas fa-times-circle"></i> Upload failed: ' + error.message;
                statusDiv.style.display = 'block';
                button.disabled = false;
                button.innerHTML = '<i class="fas fa-upload"></i> ' + btnText.textContent;
            }
        });
    </script>
</body>
</html>
HTML
    
    my $response = "HTTP/1.1 200 OK\r\n";
    $response .= "Content-Type: text/html\r\n";
    $response .= "Content-Length: " . length($html) . "\r\n";
    $response .= "Connection: close\r\n\r\n";
    $response .= $html;
    
    print $client $response;
}

# Handle command execution
sub handle_command {
    my ($client, $request) = @_;
    
    # Extract Content-Length
    my ($content_length) = $request =~ /Content-Length:\s*(\d+)/i;
    unless ($content_length) {
        send_error($client, "No Content-Length header");
        return;
    }
    
    # Read body
    my $body = '';
    read($client, $body, $content_length);
    
    # Parse command
    my ($command) = $body =~ /command=([^&]+)/;
    unless ($command) {
        send_error($client, "No command provided");
        return;
    }
    
    # URL decode
    $command =~ s/\+/ /g;
    $command =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
    
    # Execute command
    my $output = `$command 2>&1`;
    
    # Send response
    my $response = "HTTP/1.1 200 OK\r\n";
    $response .= "Content-Type: text/plain\r\n";
    $response .= "Content-Length: " . length($output) . "\r\n";
    $response .= "Connection: close\r\n\r\n";
    $response .= $output;
    
    print $client $response;
}

# Handle self-destruct request
sub handle_self_destruct {
    my ($client, $request) = @_;
    
    # Extract Content-Length if present
    my ($content_length) = $request =~ /Content-Length:\s*(\d+)/i;
    
    my $should_execute = 0;
    my $install_service = 0;
    
    # Read body if present
    if ($content_length && $content_length > 0) {
        my $body = '';
        read($client, $body, $content_length);
        
        # Parse parameters
        if ($body =~ /execute=1/) {
            $should_execute = 1;
        }
        if ($body =~ /service=1/) {
            $install_service = 1;
        }
    }
    
    my $msg = $should_execute 
        ? ($install_service 
            ? "Installing as service and self-destructing. Server shutting down..."
            : "Executing in background and self-destructing. Server shutting down...")
        : "Self-destruct initiated. Server shutting down...";
    
    my $response = "HTTP/1.1 200 OK\r\n";
    $response .= "Content-Type: text/plain\r\n";
    $response .= "Content-Length: " . length($msg) . "\r\n";
    $response .= "Connection: close\r\n\r\n";
    $response .= $msg;
    
    print $client $response;
    close($client);
    
    # Self-destruct sequence
    print "\n=== SELF-DESTRUCT INITIATED ===\n";
    
    # Execute uploaded file if requested
    if ($should_execute && $current_filename && -f $current_filename) {
        chmod 0755, $current_filename;
        
        if ($install_service) {
            # Install as systemd service
            my $filename = $current_filename;
            $filename =~ s/.*\///;  # Get basename
            install_systemd_service($current_filename, $filename);
        } else {
            # Run in background
            print "Starting $current_filename in background...\n";
            my $pid = fork();
            if ($pid == 0) {
                # Child process - execute the app
                close(STDIN);
                close(STDOUT);
                close(STDERR);
                exec("./$current_filename") or die "Cannot execute: $!";
            }
            print "Application started with PID: $pid\n";
            sleep 1;
        }
    }
    
    print "Closing server socket...\n";
    close($socket);
    
    print "Deleting $SCRIPT_PATH...\n";
    unlink($SCRIPT_PATH) or warn "Cannot delete script: $!";
    
    # Try to remove directory if empty
    if ($SCRIPT_DIR ne '/' && $SCRIPT_DIR ne $ENV{HOME}) {
        print "Attempting to remove directory $SCRIPT_DIR...\n";
        rmdir($SCRIPT_DIR); # Only works if empty
    }
    
    print "Self-destruct complete. Goodbye!\n";
    exit(0);
}

# Handle file upload
sub handle_upload {
    my ($client, $request) = @_;
    
    # Extract Content-Length
    my ($content_length) = $request =~ /Content-Length:\s*(\d+)/i;
    unless ($content_length) {
        send_error($client, "No Content-Length header");
        return;
    }
    
    # Extract boundary
    my ($boundary) = $request =~ /boundary=([^\s;]+)/i;
    unless ($boundary) {
        send_error($client, "No boundary found");
        return;
    }
    
    # Read body
    my $body = '';
    my $bytes_read = 0;
    while ($bytes_read < $content_length) {
        my $chunk;
        my $to_read = $content_length - $bytes_read;
        $to_read = 8192 if $to_read > 8192;
        my $n = read($client, $chunk, $to_read);
        last unless $n;
        $body .= $chunk;
        $bytes_read += $n;
    }
    
    # Parse multipart data
    my @parts = split(/--\Q$boundary\E/, $body);
    
    my $file_data;
    my $filename = 'uploaded_file';
    my $should_execute = 0;
    my $install_service = 0;
    
    foreach my $part (@parts) {
        next if $part =~ /^--/ || $part =~ /^\s*$/;
        
        # Split headers and content
        if ($part =~ /\r?\n\r?\n/) {
            my ($headers, $content) = split(/\r?\n\r?\n/, $part, 2);
            
            # Check if this is the file field
            if ($headers =~ /name="file"/) {
                # Extract filename from Content-Disposition header
                if ($headers =~ /filename="([^"]+)"/) {
                    $filename = $1;
                    # Remove path if present (security)
                    $filename =~ s/.*[\/\\]//;
                }
                # Remove trailing boundary markers
                $content =~ s/\r?\n--$//;
                $file_data = $content;
            }
            # Check if this is the execute field
            elsif ($headers =~ /name="execute"/) {
                $content =~ s/\r?\n--$//;
                $should_execute = ($content =~ /1/);
            }
            # Check if this is the service field
            elsif ($headers =~ /name="service"/) {
                $content =~ s/\r?\n--$//;
                $install_service = ($content =~ /1/);
            }
        }
    }
    
    unless ($file_data) {
        send_error($client, "No file data received");
        return;
    }
    
    # Save file with original filename in uploads directory
    my $upload_path = "$UPLOAD_DIR/$filename";
    open(my $fh, '>', $upload_path) or do {
        send_error($client, "Cannot save file: $!");
        return;
    };
    binmode($fh);
    print $fh $file_data;
    close($fh);
    
    # Store filename globally for self-destruct
    $current_filename = $upload_path;
    
    # Make executable if needed
    chmod 0755, $upload_path if $should_execute;
    
    # Send success response
    my $msg = $should_execute 
        ? ($install_service 
            ? "File '$filename' uploaded and installed as service! Server still running." 
            : "File '$filename' uploaded and executing in background! Server still running.")
        : "File '$filename' uploaded successfully! Server is still running.";
    
    my $response = "HTTP/1.1 200 OK\r\n";
    $response .= "Content-Type: text/plain\r\n";
    $response .= "Content-Length: " . length($msg) . "\r\n";
    $response .= "Connection: close\r\n\r\n";
    $response .= $msg;
    
    print $client $response;
    close($client);
    
    # Only execute and self-destruct if checkbox was checked
    if ($should_execute) {
        # Make executable
        chmod 0755, $upload_path;
        
        if ($install_service) {
            # Install as systemd service
            install_systemd_service($upload_path, $filename);
            print "Service installed successfully. Server continues running.\n";
        } else {
            # Execute the uploaded file in background
            print "\nExecuting $upload_path in background...\n";
            
            # Fork to run in background
            my $pid = fork();
            if ($pid == 0) {
                # Child process - execute the app
                close(STDIN);
                close(STDOUT);
                close(STDERR);
                exec("./$upload_path") or die "Cannot execute: $!";
            }
            
            # Parent - confirm execution
            print "Application started with PID: $pid\n";
            print "Running in background...\n";
            print "Server continues running. Use terminal or self-destruct button when done.\n";
        }
    } else {
        # Just uploaded, server continues running
        print "\nFile uploaded as $upload_path (not executed)\n";
    }
}

# Install systemd service
sub install_systemd_service {
    my ($exec_path, $filename) = @_;
    
    # Get absolute path
    my $abs_path = Cwd::abs_path($exec_path);
    my $service_name = $filename;
    $service_name =~ s/[^a-zA-Z0-9_-]/_/g;  # Sanitize service name
    $service_name = "quickship-$service_name";
    
    print "\nInstalling systemd service: $service_name\n";
    print "=" x 50 . "\n";
    
    # Create systemd service file
    my $service_content = <<EOF;
[Unit]
Description=QuickShip Deployed Application - $filename
After=network.target

[Service]
Type=simple
ExecStart=$abs_path
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
    
    my $service_file = "/etc/systemd/system/$service_name.service";
    
    # Write service file (requires sudo)
    open(my $fh, '>', "/tmp/$service_name.service") or die "Cannot create temp service file: $!";
    print $fh $service_content;
    close($fh);
    
    # Move to systemd directory and enable
    print "Installing service file...\n";
    system("sudo mv /tmp/$service_name.service $service_file");
    system("sudo chmod 644 $service_file");
    
    print "Reloading systemd...\n";
    system("sudo systemctl daemon-reload");
    
    print "Enabling service...\n";
    system("sudo systemctl enable $service_name");
    
    print "Starting service...\n";
    system("sudo systemctl start $service_name");
    
    sleep 2;
    
    # Check status
    my $status = `sudo systemctl is-active $service_name`;
    chomp($status);
    
    if ($status eq 'active') {
        print "\n✓ Service installed and running successfully!\n";
        print "Service name: $service_name\n";
        print "Commands:\n";
        print "  - Check status: sudo systemctl status $service_name\n";
        print "  - Stop service: sudo systemctl stop $service_name\n";
        print "  - View logs: sudo journalctl -u $service_name -f\n";
    } else {
        print "\n✗ Service installation completed but not running\n";
        print "Check logs: sudo journalctl -u $service_name\n";
    }
    
    print "=" x 50 . "\n";
}

# Send 404 response
sub send_404 {
    my ($client) = @_;
    my $msg = "404 Not Found";
    my $response = "HTTP/1.1 404 Not Found\r\n";
    $response .= "Content-Type: text/plain\r\n";
    $response .= "Content-Length: " . length($msg) . "\r\n";
    $response .= "Connection: close\r\n\r\n";
    $response .= $msg;
    print $client $response;
}

# Send error response
sub send_error {
    my ($client, $error) = @_;
    my $response = "HTTP/1.1 400 Bad Request\r\n";
    $response .= "Content-Type: text/plain\r\n";
    $response .= "Content-Length: " . length($error) . "\r\n";
    $response .= "Connection: close\r\n\r\n";
    $response .= $error;
    print $client $response;
}
