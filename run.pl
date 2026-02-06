#!/usr/bin/env perl
use strict;
use warnings;
use IO::Socket::INET;
use File::Basename;
use Cwd 'abs_path';

# Configuration
my $PORT = 8888;
my $UPLOAD_FILE = 'app_executable';

# Get script location for self-destruct
my $SCRIPT_PATH = abs_path($0);
my $SCRIPT_DIR = dirname($SCRIPT_PATH);

print "Starting Disposable Deployment Server on port $PORT...\n";
print "Access at: http://YOUR_VPS_IP:$PORT\n";
print "Script location: $SCRIPT_PATH\n";
print "Working directory: $SCRIPT_DIR\n\n";

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
        .warning {
            background: #fff3cd;
            border: 1px solid #ffc107;
            padding: 10px;
            border-radius: 4px;
            margin: 15px 0;
            color: #856404;
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
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Disposable Deployment</h1>
        <div class="warning">
            <strong>⚠️ Warning:</strong> This server will self-destruct after deployment!
        </div>
        <form id="uploadForm" enctype="multipart/form-data">
            <label for="file"><strong>Select executable file:</strong></label>
            <input type="file" id="file" name="file" required>
            <button type="submit">Deploy & Self-Destruct</button>
        </form>
        <div class="progress-container" id="progressContainer">
            <div class="progress-bar">
                <div class="progress-text" id="progressText">0%</div>
                <div class="progress-fill" id="progressFill"></div>
            </div>
        </div>
        <div id="status"></div>
    </div>
    
    <script>
        document.getElementById('uploadForm').addEventListener('submit', async (e) => {
            e.preventDefault();
            
            const fileInput = document.getElementById('file');
            const statusDiv = document.getElementById('status');
            const button = e.target.querySelector('button');
            const progressContainer = document.getElementById('progressContainer');
            const progressFill = document.getElementById('progressFill');
            const progressText = document.getElementById('progressText');
            
            if (!fileInput.files[0]) {
                statusDiv.className = 'error';
                statusDiv.textContent = 'Please select a file';
                statusDiv.style.display = 'block';
                return;
            }
            
            button.disabled = true;
            button.textContent = 'Uploading...';
            statusDiv.style.display = 'none';
            progressContainer.style.display = 'block';
            progressFill.style.width = '0%';
            progressText.textContent = '0%';
            
            const formData = new FormData();
            formData.append('file', fileInput.files[0]);
            
            try {
                const xhr = new XMLHttpRequest();
                
                // Track upload progress
                xhr.upload.addEventListener('progress', (e) => {
                    if (e.lengthComputable) {
                        const percentComplete = Math.round((e.loaded / e.total) * 100);
                        progressFill.style.width = percentComplete + '%';
                        progressText.textContent = percentComplete + '%';
                        
                        if (percentComplete === 100) {
                            button.textContent = 'Processing...';
                        }
                    }
                });
                
                // Handle completion
                xhr.addEventListener('load', () => {
                    progressContainer.style.display = 'none';
                    
                    if (xhr.status === 200) {
                        statusDiv.className = 'success';
                        statusDiv.textContent = '✓ ' + xhr.responseText;
                        statusDiv.style.display = 'block';
                        button.textContent = 'Deployed!';
                        
                        setTimeout(() => {
                            statusDiv.textContent += '\n\nServer has self-destructed. You can close this page.';
                        }, 1000);
                    } else {
                        statusDiv.className = 'error';
                        statusDiv.textContent = '✗ ' + xhr.responseText;
                        statusDiv.style.display = 'block';
                        button.disabled = false;
                        button.textContent = 'Deploy & Self-Destruct';
                    }
                });
                
                // Handle errors
                xhr.addEventListener('error', () => {
                    progressContainer.style.display = 'none';
                    statusDiv.className = 'error';
                    statusDiv.textContent = '✗ Upload failed: Network error';
                    statusDiv.style.display = 'block';
                    button.disabled = false;
                    button.textContent = 'Deploy & Self-Destruct';
                });
                
                xhr.open('POST', '/upload');
                xhr.send(formData);
                
            } catch (error) {
                progressContainer.style.display = 'none';
                statusDiv.className = 'error';
                statusDiv.textContent = '✗ Upload failed: ' + error.message;
                statusDiv.style.display = 'block';
                button.disabled = false;
                button.textContent = 'Deploy & Self-Destruct';
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
    foreach my $part (@parts) {
        next if $part =~ /^--/ || $part =~ /^\s*$/;
        
        # Split headers and content
        if ($part =~ /\r?\n\r?\n/) {
            my ($headers, $content) = split(/\r?\n\r?\n/, $part, 2);
            
            # Check if this is the file field
            if ($headers =~ /name="file"/) {
                # Remove trailing boundary markers
                $content =~ s/\r?\n--$//;
                $file_data = $content;
                last;
            }
        }
    }
    
    unless ($file_data) {
        send_error($client, "No file data received");
        return;
    }
    
    # Save file
    open(my $fh, '>', $UPLOAD_FILE) or do {
        send_error($client, "Cannot save file: $!");
        return;
    };
    binmode($fh);
    print $fh $file_data;
    close($fh);
    
    # Make executable
    chmod 0755, $UPLOAD_FILE;
    
    # Send success response
    my $msg = "Deployment successful! Executing and self-destructing...";
    my $response = "HTTP/1.1 200 OK\r\n";
    $response .= "Content-Type: text/plain\r\n";
    $response .= "Content-Length: " . length($msg) . "\r\n";
    $response .= "Connection: close\r\n\r\n";
    $response .= $msg;
    
    print $client $response;
    close($client);
    
    # Execute the uploaded file in background
    print "\nExecuting $UPLOAD_FILE...\n";
    
    # Fork and execute
    my $pid = fork();
    if ($pid == 0) {
        # Child process - execute the app
        close(STDIN);
        close(STDOUT);
        close(STDERR);
        exec("./$UPLOAD_FILE") or die "Cannot execute: $!";
    }
    
    # Parent process - self-destruct
    print "Application started with PID: $pid\n";
    print "Initiating self-destruct sequence...\n";
    
    sleep 1; # Give time for response to be sent
    
    # Close server socket
    close($socket);
    
    # Self-destruct
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
