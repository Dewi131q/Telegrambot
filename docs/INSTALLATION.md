# Installation Guide

## Prerequisites

Before installing the VPN Auto Install Script, ensure your system meets the following requirements:

### System Requirements
- **Operating System**: Debian 10/11 or Ubuntu 20.04+
- **Architecture**: x86_64 / amd64
- **RAM**: Minimum 512MB (1GB recommended)
- **Storage**: Minimum 10GB free space
- **Network**: Stable internet connection
- **Access**: Root access required

### Software Requirements
- Bash shell
- curl or wget
- Internet connection for package downloads

## Installation Methods

### Method 1: Direct Download (Recommended)

1. **Download the script**
   ```bash
   wget -O install.sh https://raw.githubusercontent.com/username/vpn-script/main/install.sh
   ```

2. **Make it executable**
   ```bash
   chmod +x install.sh
   ```

3. **Run the installation**
   ```bash
   ./install.sh
   ```

### Method 2: Git Clone

1. **Clone the repository**
   ```bash
   git clone https://github.com/username/vpn-script.git
   cd vpn-script
   ```

2. **Run the installation**
   ```bash
   chmod +x install.sh
   ./install.sh
   ```

### Method 3: One-liner Installation

```bash
bash <(curl -s https://raw.githubusercontent.com/username/vpn-script/main/install.sh)
```

## Installation Process

The installation script will perform the following steps:

### 1. System Check
- Verify operating system compatibility
- Check for root access
- Validate system requirements

### 2. Package Installation
- Update system packages
- Install required dependencies:
  - curl, wget, git, nano, unzip, zip
  - openssh-server, dropbear, nginx
  - apache2-utils

### 3. Directory Setup
- Create necessary directories:
  - `/etc/xray/` - Configuration files
  - `/var/log/xray/` - Log files
  - `/usr/local/bin/vpn/` - Script files
  - `/home/vps/public_html/` - Web interface

### 4. Script Installation
- Download and install all VPN scripts
- Set proper permissions
- Create system aliases

### 5. Service Configuration
- Configure Dropbear SSH server
- Setup Nginx web server
- Create web interface
- Set default domain

### 6. Final Setup
- Create alias for easy access
- Start the VPN menu
- Display completion message

## Post-Installation

### Accessing the Menu

After installation, you can access the VPN menu using:

```bash
vpn
```

Or directly:

```bash
source /usr/local/bin/vpn/menu.sh
```

### Web Interface

Access the web dashboard at:
- **URL**: `http://YOUR_SERVER_IP/`
- **Account Files**: `http://YOUR_SERVER_IP/akun/`

### Default Configuration

- **Domain**: localhost (change via menu)
- **SSH Port**: 22
- **Web Port**: 80
- **VPN Port**: 443

## Verification

### Check Installation

1. **Verify script installation**
   ```bash
   ls -la /usr/local/bin/vpn/
   ```

2. **Check services**
   ```bash
   systemctl status nginx dropbear
   ```

3. **Test menu access**
   ```bash
   vpn
   ```

### Common Verification Commands

```bash
# Check if all scripts are executable
ls -la /usr/local/bin/vpn/*.sh

# Verify web interface
curl -I http://localhost/

# Check domain configuration
cat /etc/xray/domain

# Verify alias creation
alias | grep vpn
```

## Troubleshooting

### Common Issues

#### 1. Permission Denied
```bash
chmod +x install.sh
```

#### 2. Package Installation Failed
```bash
apt update && apt upgrade -y
apt install -y curl wget
```

#### 3. Service Not Starting
```bash
# Check service status
systemctl status nginx
systemctl status dropbear

# Restart services
systemctl restart nginx
systemctl restart dropbear
```

#### 4. Menu Not Accessible
```bash
# Reload bashrc
source ~/.bashrc

# Or run directly
source /usr/local/bin/vpn/menu.sh
```

### Log Files

Check these log files for troubleshooting:

- **Nginx**: `/var/log/nginx/error.log`
- **System**: `/var/log/syslog`
- **SSH**: `/var/log/auth.log`

### Network Issues

If you can't access the web interface:

1. **Check firewall**
   ```bash
   ufw status
   ```

2. **Open required ports**
   ```bash
   ufw allow 80
   ufw allow 443
   ufw allow 22
   ```

3. **Check nginx configuration**
   ```bash
   nginx -t
   ```

## Uninstallation

To remove the VPN script:

```bash
# Remove scripts
rm -rf /usr/local/bin/vpn/

# Remove alias
sed -i '/alias vpn=/d' ~/.bashrc

# Remove web files (optional)
rm -rf /home/vps/public_html/

# Remove configuration (optional)
rm -rf /etc/xray/
```

## Security Considerations

### After Installation

1. **Change default domain**
   ```bash
   vpn
   # Select option 5: Change Domain
   ```

2. **Set up firewall**
   ```bash
   ufw enable
   ufw allow 22
   ufw allow 80
   ufw allow 443
   ```

3. **Update system regularly**
   ```bash
   apt update && apt upgrade -y
   ```

4. **Monitor logs**
   ```bash
   tail -f /var/log/syslog
   ```

## Support

If you encounter issues during installation:

1. Check the troubleshooting section above
2. Review log files for errors
3. Ensure system meets requirements
4. Contact support with detailed error information

## Next Steps

After successful installation:

1. **Configure your domain** (if you have one)
2. **Create your first VPN account**
3. **Set up SSL certificate** (recommended)
4. **Configure backup system**
5. **Set up monitoring**

For detailed usage instructions, see the [Usage Guide](USAGE.md).