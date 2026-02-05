# QuickShip Deployment Toolkit

[![Test QuickShip](https://github.com/RedZONERROR/QuickShip/actions/workflows/test.yml/badge.svg)](https://github.com/RedZONERROR/QuickShip/actions/workflows/test.yml)
[![Auto Release](https://github.com/RedZONERROR/QuickShip/actions/workflows/auto-release.yml/badge.svg)](https://github.com/RedZONERROR/QuickShip/actions/workflows/auto-release.yml)
[![GitHub release (latest by date)](https://img.shields.io/github/v/release/RedZONERROR/QuickShip)](https://github.com/RedZONERROR/QuickShip/releases/latest)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Bash](https://img.shields.io/badge/bash-5.0+-green.svg)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/platform-linux-lightgrey.svg)](https://www.linux.org/)

A modular, zero-dependency deployment system using only bash and netcat. Deploy services to your VPS with a web interface - no Python, Node.js, PHP, or Docker required.

## Features

- **File Upload**: Upload any file to your VPS
- **Service Deployment**: Automatically install binaries and create systemd services
- **Web Terminal**: Execute shell commands directly from the browser
- **Self-Destruct**: Complete cleanup with the nuke function

## Requirements

- Linux VPS with bash
- netcat (nc)
- systemd (for service management)
- sudo access (for service installation)

## Installation

1. Upload QuickShip to your VPS:
```bash
# Clone or upload the entire directory
cd /opt
git clone https://github.com/RedZONERROR/QuickShip.git quickship
cd quickship
```

2. Make scripts executable:
```bash
chmod +x main.sh
chmod +x modules/*.sh
```

3. Start the server:
```bash
./main.sh
```

## Usage

### Starting the Server

```bash
./main.sh
```

Default: http://0.0.0.0:8080

Custom host/port:
```bash
QUICKSHIP_HOST=192.168.1.100 QUICKSHIP_PORT=9000 ./main.sh
```

### Accessing the Dashboard

Open your browser and navigate to:
```
http://YOUR_VPS_IP:8080
```

### Uploading Files

1. **Regular File Upload**: Select a file and click Upload (stores in ./uploads/)
2. **Service Deployment**: Check "Run as Service" to:
   - Install binary to /usr/local/bin
   - Create systemd service
   - Auto-start with Restart=always

### Web Terminal

Execute any shell command directly from the browser. Output is displayed in real-time.

### Nuke Everything

The nuclear option:
- Stops all QuickShip services
- Removes all installed binaries
- Deletes all service files
- Removes the entire QuickShip directory

## Architecture

```
quickship/
├── main.sh                 # Entry point
├── config.sh               # Configuration
├── modules/
│   ├── http_server.sh      # Netcat-based HTTP server
│   ├── req_parser.sh       # Multipart form parser
│   ├── file_handler.sh     # File storage/installation
│   ├── cmd_runner.sh       # Command execution
│   ├── service_mgr.sh      # Systemd service manager
│   └── nuke.sh             # Self-destruct
└── views/
    └── dashboard.html      # Web interface
```

## Security Warning

⚠️ **NO AUTHENTICATION** - This system has zero security by design. Only use on:
- Private networks
- Trusted environments
- Behind a firewall
- For temporary deployments

## How It Works

1. **HTTP Server**: Pure bash + netcat loop listening on port 8080
2. **Request Routing**: Parses HTTP headers and routes to appropriate handlers
3. **File Upload**: Parses multipart/form-data in pure bash
4. **Service Creation**: Generates systemd unit files and manages lifecycle
5. **Command Execution**: Runs shell commands and returns JSON responses

## Troubleshooting

**Port already in use:**
```bash
# Kill existing process
sudo lsof -ti:8080 | xargs kill -9

# Or use different port
QUICKSHIP_PORT=9000 ./main.sh
```

**Permission denied:**
```bash
# Ensure scripts are executable
chmod +x main.sh modules/*.sh

# Run with sudo if needed for service management
sudo ./main.sh
```

**Service creation fails:**
```bash
# Ensure systemd is available
systemctl --version

# Check sudo access
sudo -v
```

## License

Use at your own risk. No warranty provided.

## Release Process

Releases are **fully automated** using semantic versioning based on commit messages. Version numbers are managed through **git tags only** - no VERSION file needed.

### Commit Message Convention

- `feat:` or `feature:` - Bumps **minor** version (e.g., 1.0.0 → 1.1.0)
- `fix:` or `bugfix:` - Bumps **patch** version (e.g., 1.0.0 → 1.0.1)
- `breaking:` or `major:` - Bumps **major** version (e.g., 1.0.0 → 2.0.0)
- Other commits - Bumps **patch** version by default

### Example Commits

```bash
git commit -m "feat: add file compression support"        # 1.0.0 → 1.1.0
git commit -m "fix: resolve upload timeout issue"        # 1.0.0 → 1.0.1
git commit -m "breaking: change API endpoint structure"  # 1.0.0 → 2.0.0
```

### Automated Workflow

When you push to `main`:
1. ✅ All tests run automatically
2. 🔢 Version is calculated from the latest git tag and commit messages
3. 📝 Release notes are generated with categorized changes
4. 🏷️ New git tag is created and pushed
5. 🚀 GitHub release is published with installation instructions

**Single source of truth:** Git tags are the only version reference - clean and simple!
