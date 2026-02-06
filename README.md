# QuickShip 🚀

[![Latest Release](https://img.shields.io/github/v/release/RedZONERROR/QuickShip?color=blue)](https://github.com/RedZONERROR/QuickShip/releases/latest)
[![Tests](https://github.com/RedZONERROR/QuickShip/actions/workflows/test.yml/badge.svg)](https://github.com/RedZONERROR/QuickShip/actions/workflows/test.yml)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Perl](https://img.shields.io/badge/perl-5.x-purple.svg)](https://www.perl.org/)
[![Platform](https://img.shields.io/badge/platform-linux-lightgrey.svg)](https://github.com/RedZONERROR/QuickShip)
[![GitHub Stars](https://img.shields.io/github/stars/RedZONERROR/QuickShip?style=social)](https://github.com/RedZONERROR/QuickShip/stargazers)

A single-use Perl script for deploying executables to a Linux VPS without FTP or SSH keys. Upload, deploy, and self-destruct in seconds.

## Quick Start

### Basic Usage (No Service Installation)

Paste this into your VPS terminal:

```bash
git clone https://github.com/RedZONERROR/QuickShip.git && cd QuickShip && perl run.pl
```

### With Service Support (Recommended for Persistent Apps)

For systemd service installation capability (auto-restart on reboot):

```bash
git clone https://github.com/RedZONERROR/QuickShip.git && cd QuickShip && sudo perl run.pl
```

**Note:** Running with `sudo` allows the service installation feature to work. Without sudo, you can still upload and execute files, but cannot install them as persistent services.

### Download Script Only

Or download the latest release directly:

```bash
# Without sudo (basic usage)
curl -O https://raw.githubusercontent.com/RedZONERROR/QuickShip/main/run.pl && perl run.pl

# With sudo (service support)
curl -O https://raw.githubusercontent.com/RedZONERROR/QuickShip/main/run.pl && sudo perl run.pl
```

Or using wget:

```bash
# Without sudo (basic usage)
wget https://raw.githubusercontent.com/RedZONERROR/QuickShip/main/run.pl && perl run.pl

# With sudo (service support)
wget https://raw.githubusercontent.com/RedZONERROR/QuickShip/main/run.pl && sudo perl run.pl
```

## What It Does

1. Starts an HTTP server on port 8888
2. Serves a web interface for file upload with progress tracking
3. Accepts your executable files (keeps original filename)
4. **Three deployment modes:**
   - **Upload Only**: Just upload files, server keeps running
   - **Upload & Execute**: Run executable in background, server keeps running
   - **Install as Service**: Install as systemd service (persistent, auto-restart on reboot, auto self-destruct)
5. Integrated terminal for command execution
6. Manual self-destruct button
7. **Self-destructs only when:** service is installed OR self-destruct button is clicked

## Usage

### 1. Start the server

**Without sudo (basic features):**
```bash
perl run.pl
```

**With sudo (enables service installation):**
```bash
sudo perl run.pl
```

### 2. Access the web interface

Open your browser to:
```
http://YOUR_VPS_IP:8888
```

### 3. Upload and deploy

**Option A: Upload Only**
- Uncheck "Execute as application"
- Upload any file
- Server continues running
- Use terminal to manage files

**Option B: Upload & Execute**
- Check "Execute as application"
- Uncheck "Install as systemd service"
- Upload your executable
- File runs in background
- **Server continues running** - use self-destruct button when done

**Option C: Install as Persistent Service** (requires sudo)
- Check "Install as systemd service"
- Upload your executable
- Installs as systemd service
- Auto-starts on VPS reboot
- **Server self-destructs automatically**

### 4. Additional Features

**Integrated Terminal:**
- Click "Open Terminal" button
- Execute any shell command
- Full system access

**Manual Self-Destruct:**
- Click "Self-Destruct Server" button
- If "Execute" is checked: runs uploaded file then self-destructs
- If "Execute" is unchecked: just self-destructs
- Removes run.pl and stops server

## Features

- 📤 **Web-based file upload** with real-time progress tracking
- 🎯 **Original filename preservation** - files saved with their upload names
- 🔄 **Three deployment modes:**
  - Upload only (server keeps running)
  - Upload & execute in background (server keeps running)
  - Install as persistent systemd service (auto self-destruct)
- 🖥️ **Integrated terminal** with command execution (modal interface)
- 💣 **Manual self-destruct** button with optional execution
- 🎨 **Modern UI** with Font Awesome icons
- 🔒 **Core modules only** - no CPAN dependencies required
- ⚡ **Lightweight** - single Perl script
- 🔁 **Auto-restart** - systemd service survives crashes and reboots

## Service Management

When you install an executable as a systemd service, you can manage it with:

```bash
# Check service status
sudo systemctl status quickship-yourapp

# View live logs
sudo journalctl -u quickship-yourapp -f

# Stop service
sudo systemctl stop quickship-yourapp

# Disable auto-start
sudo systemctl disable quickship-yourapp

# Remove service
sudo systemctl stop quickship-yourapp
sudo systemctl disable quickship-yourapp
sudo rm /etc/systemd/system/quickship-yourapp.service
sudo systemctl daemon-reload
```

## Security Notes

- ⚠️ **No authentication** - anyone who can access the port can upload files
- ⚠️ **Terminal has full system access** - use only in trusted environments
- ⚠️ **Service installation requires sudo** - grants elevated privileges
- 🔒 **Designed for temporary/disposable deployments**
- 🔒 **Use firewall rules** to restrict access to port 8888
- 🔒 **Consider SSH tunneling** for secure access: `ssh -L 8888:localhost:8888 user@vps`

## Requirements

- Linux VPS with Perl 5.x (pre-installed on most systems)
- Port 8888 available (or modify the `$PORT` variable)
- **For service installation:** sudo/root access
- No additional dependencies (uses only Perl core modules)

## Customization

Edit these variables in `run.pl`:

- `$PORT` - Change the server port (default: 8888)
- `$UPLOAD_DIR` - Change upload directory (default: uploads)

- `$PORT` - Change the server port (default: 8888)
- `$UPLOAD_FILE` - Change the output filename (default: app_executable)

## Troubleshooting

**Port already in use:**
```bash
# Check what's using port 8888
sudo netstat -tlnp | grep 8888

# Or change the port in the script
```

**Permission denied:**
```bash
chmod +x run.pl
perl run.pl
```

**Service installation fails:**
```bash
# Make sure you're running with sudo
sudo perl run.pl

# Check if systemd is available
systemctl --version
```

**Uploaded file won't execute:**
```bash
# Check file permissions in uploads directory
ls -la uploads/

# Manually make executable
chmod +x uploads/yourfile
```

**Firewall blocking:**
```bash
# Allow port 8888 (Ubuntu/Debian)
sudo ufw allow 8888

# Or (CentOS/RHEL)
sudo firewall-cmd --add-port=8888/tcp
```

## Changelog

### (Initial Release)
- ✨ HTTP server with web interface
- 📤 File upload via browser
- 🔧 Automatic chmod +x and execution
- 💥 Self-destruct after deployment
- 🎨 Clean, modern UI
- 🔒 Core Perl modules only (no CPAN dependencies)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - Use at your own risk

---

Made with ❤️ for quick and dirty deployments
