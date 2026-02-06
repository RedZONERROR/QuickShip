# QuickShip 🚀

[![Latest Release](https://img.shields.io/github/v/release/RedZONERROR/QuickShip?color=blue)](https://github.com/RedZONERROR/QuickShip/releases/latest)
[![Tests](https://github.com/RedZONERROR/QuickShip/actions/workflows/test.yml/badge.svg)](https://github.com/RedZONERROR/QuickShip/actions/workflows/test.yml)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Perl](https://img.shields.io/badge/perl-5.x-purple.svg)](https://www.perl.org/)
[![Platform](https://img.shields.io/badge/platform-linux-lightgrey.svg)](https://github.com/RedZONERROR/QuickShip)
[![GitHub Stars](https://img.shields.io/github/stars/RedZONERROR/QuickShip?style=social)](https://github.com/RedZONERROR/QuickShip/stargazers)

A single-use Perl script for deploying executables to a Linux VPS without FTP or SSH keys. Upload, deploy, and self-destruct in seconds.

## Quick Start

Paste this into your VPS terminal:

```bash
git clone https://github.com/RedZONERROR/QuickShip.git && cd QuickShip && perl run.pl
```

Or download the latest release directly:

```bash
curl -O https://raw.githubusercontent.com/RedZONERROR/QuickShip/main/run.pl && perl run.pl
```

Or using wget:

```bash
wget https://raw.githubusercontent.com/RedZONERROR/QuickShip/main/run.pl && perl run.pl
```

## What It Does

1. Starts an HTTP server on port 8888
2. Serves a web interface for file upload
3. Accepts your Node.js executable
4. Makes it executable (`chmod +x`)
5. Runs it in the background
6. **Self-destructs** (deletes itself and exits)

## Usage

1. Run the script on your VPS:
   ```bash
   perl run.pl
   ```

2. Open your browser to:
   ```
   http://YOUR_VPS_IP:8888
   ```

3. Upload your Node.js executable file

4. Click "Deploy & Self-Destruct"

5. The script will:
   - Save your file as `app_executable`
   - Execute it in the background
   - Delete itself
   - Exit

## Requirements

- Linux VPS
- Perl (pre-installed on most Linux systems)
- Port 8888 open (or modify the `$PORT` variable in the script)

## Security Notes

- This is designed for **one-time use** in trusted environments
- No authentication - anyone who can access the port can upload
- The script self-destructs after deployment
- Use only for temporary/disposable deployments
- Consider firewall rules to restrict access to port 8888

## Customization

Edit these variables in `run.pl`:

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
