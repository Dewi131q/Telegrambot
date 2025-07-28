# Usage Guide

## Getting Started

After successful installation, you can start using the VPN Auto Install Script.

### Accessing the Menu

```bash
vpn
```

This will display the main menu with all available options.

## Main Menu Options

### 1. Create SSH Account

Creates a new SSH account with full configuration.

**Steps:**
1. Select option `1` from the main menu
2. Enter username
3. Enter password (hidden input)
4. Enter duration in days
5. Enter IP limit
6. Enter quota in GB

**Output:**
- Creates system user account
- Sets account expiration
- Generates account file with details
- Includes WebSocket payload

**Example Output:**
```
╔══════════════════════════════════════════════════════════════╗
║                        SSH ACCOUNT                           ║
╠══════════════════════════════════════════════════════════════╣
║  Username    : user123                                       ║
║  Password    : password123                                   ║
║  IP Address  : 192.168.1.100                                ║
║  Port        : 22                                            ║
║  Duration    : 30 days                                       ║
║  IP Limit    : 2                                             ║
║  Quota       : 10 GB                                         ║
║                                                              ║
║  WebSocket Payload:                                          ║
║  GET / HTTP/1.1[crlf]Host: [host][crlf]Upgrade: websocket[crlf][crlf] ║
╚══════════════════════════════════════════════════════════════╝
```

### 2. Create VLESS Account

Creates a new VLESS account with WebSocket support.

**Steps:**
1. Select option `2` from the main menu
2. Enter username
3. Enter duration in days

**Output:**
- Generates UUID automatically
- Creates JSON configuration
- Generates account file with VLESS link

**Example Output:**
```
╔══════════════════════════════════════════════════════════════╗
║                        VLESS ACCOUNT                         ║
╠══════════════════════════════════════════════════════════════╣
║  Username    : vless123                                      ║
║  UUID        : 12345678-1234-1234-1234-123456789012        ║
║  IP Address  : 192.168.1.100                                ║
║  Port        : 443                                           ║
║  Duration    : 30 days                                       ║
║  Domain      : example.com                                   ║
║  Path        : /vless                                        ║
║  Security    : TLS                                           ║
║                                                              ║
║  VLESS Link:                                                 ║
║  vless://12345678-1234-1234-1234-123456789012@example.com:443?encryption=none&security=tls&type=ws&path=%2Fvless#example.com ║
╚══════════════════════════════════════════════════════════════╝
```

### 3. Create VMess Account

Creates a new VMess account with WebSocket support.

**Steps:**
1. Select option `3` from the main menu
2. Enter username
3. Enter duration in days

**Output:**
- Generates UUID automatically
- Creates JSON configuration
- Generates account file with VMess link

**Example Output:**
```
╔══════════════════════════════════════════════════════════════╗
║                        VMESS ACCOUNT                         ║
╠══════════════════════════════════════════════════════════════╣
║  Username    : vmess123                                      ║
║  UUID        : 87654321-4321-4321-4321-210987654321        ║
║  IP Address  : 192.168.1.100                                ║
║  Port        : 443                                           ║
║  Duration    : 30 days                                       ║
║  Domain      : example.com                                   ║
║  Path        : /vmess                                        ║
║  Security    : TLS                                           ║
║                                                              ║
║  VMess Link:                                                 ║
║  vmess://eyJ2IjoiMiIsInBzIjoiZXhhbXBsZSIsImFkZCI6ImV4YW1wbGUuY29tIiwicG9ydCI6IjQ0MyIsImlkIjoiMTIzNDU2NzgtMTIzNC0xMjM0LTEyMzQtMTIzNDU2Nzg5MDEyIiwiYWlkIjoiMCIsIm5ldCI6IndzIiwidHlwZSI6Im5vbmUiLCJob3N0IjoiZXhhbXBsZS5jb20iLCJwYXRoIjoiL3ZtZXNzIiwidGxzIjoidGxzIn0= ║
╚══════════════════════════════════════════════════════════════╝
```

### 4. Create Trojan Account

Creates a new Trojan account with WebSocket support.

**Steps:**
1. Select option `4` from the main menu
2. Enter username
3. Enter duration in days

**Output:**
- Generates random password automatically
- Creates JSON configuration
- Generates account file with Trojan link

**Example Output:**
```
╔══════════════════════════════════════════════════════════════╗
║                       TROJAN ACCOUNT                        ║
╠══════════════════════════════════════════════════════════════╣
║  Username    : trojan123                                     ║
║  Password    : aBcDeFgHiJkLmNoPqRsTuVwXyZ1234567890        ║
║  IP Address  : 192.168.1.100                                ║
║  Port        : 443                                           ║
║  Duration    : 30 days                                       ║
║  Domain      : example.com                                   ║
║  Path        : /trojan                                       ║
║  Security    : TLS                                           ║
║                                                              ║
║  Trojan Link:                                                ║
║  trojan://aBcDeFgHiJkLmNoPqRsTuVwXyZ1234567890@example.com:443?security=tls&type=ws&path=%2Ftrojan#trojan123 ║
╚══════════════════════════════════════════════════════════════╝
```

### 5. Change Domain

Changes the server domain used for VPN connections.

**Steps:**
1. Select option `5` from the main menu
2. Enter new domain name
3. Confirm the change

**Example:**
```
Current domain: localhost
Enter new domain: myvpn.com
✓ Domain changed to: myvpn.com
```

### 6. Change Banner

Customizes the server banner displayed to users.

**Steps:**
1. Select option `6` from the main menu
2. Enter your custom banner text
3. Press Enter twice to finish

**Example:**
```
Enter your custom banner text:
(Press Enter twice to finish)

Welcome to My VPN Server
========================
Server Status: Online
Support: support@example.com
```

### 7. Check Active Ports

Displays the status of common ports and services.

**Output:**
```
Checking active ports...

✓ Port 22 is OPEN
✓ Port 80 is OPEN
✗ Port 443 is CLOSED
✗ Port 8080 is CLOSED
✗ Port 8443 is CLOSED
✗ Port 8880 is CLOSED
✗ Port 2083 is CLOSED
✗ Port 2087 is CLOSED
✗ Port 2096 is CLOSED
✗ Port 9443 is CLOSED

Detailed port information:
tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN
tcp        0      0 0.0.0.0:80              0.0.0.0:*               LISTEN
```

### 8. Exit

Exits the VPN menu and returns to the command line.

## Web Interface

### Accessing Account Files

All account files are automatically saved and accessible via web browser:

- **Main Dashboard**: `http://YOUR_SERVER_IP/`
- **Account Files**: `http://YOUR_SERVER_IP/akun/`

### Account File Structure

Account files are saved in `/home/vps/public_html/akun/` with the following naming convention:

- SSH accounts: `username.txt`
- VLESS accounts: `vless_username.txt`
- VMess accounts: `vmess_username.txt`
- Trojan accounts: `trojan_username.txt`

## Advanced Usage

### Direct Script Execution

You can run individual scripts directly:

```bash
# SSH account creation
source /usr/local/bin/vpn/ssh.sh

# VLESS account creation
source /usr/local/bin/vpn/vless.sh

# VMess account creation
source /usr/local/bin/vpn/vmess.sh

# Trojan account creation
source /usr/local/bin/vpn/trojan.sh

# Domain change
source /usr/local/bin/vpn/domain.sh

# Banner change
source /usr/local/bin/vpn/banner.sh

# Port check
source /usr/local/bin/vpn/cekport.sh
```

### Configuration Files

#### Domain Configuration
```bash
# View current domain
cat /etc/xray/domain

# Change domain manually
echo "newdomain.com" > /etc/xray/domain
```

#### Banner Configuration
```bash
# View current banner
cat /etc/issue.net

# Change banner manually
echo "Custom Banner" > /etc/issue.net
```

### Service Management

#### Check Service Status
```bash
# Check all services
systemctl status nginx dropbear xray

# Check specific service
systemctl status nginx
```

#### Restart Services
```bash
# Restart all services
systemctl restart nginx dropbear

# Restart specific service
systemctl restart nginx
```

#### Enable/Disable Services
```bash
# Enable services
systemctl enable nginx dropbear

# Disable services
systemctl disable nginx dropbear
```

## Monitoring and Maintenance

### System Information

The menu displays real-time system information:

- **IP VPS**: Current public IP address
- **RAM**: Available system memory
- **CPU Core**: Number of CPU cores
- **Domain**: Configured domain name
- **Creator**: Script author information

### Service Status

The menu shows the status of key services:

- **Dropbear**: SSH server status
- **Nginx**: Web server status
- **XRAY**: VPN server status

### Log Monitoring

Monitor system logs for troubleshooting:

```bash
# Nginx logs
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log

# System logs
tail -f /var/log/syslog

# SSH logs
tail -f /var/log/auth.log
```

## Best Practices

### Account Management

1. **Use strong passwords** for SSH accounts
2. **Set reasonable expiration dates** for all accounts
3. **Monitor account usage** regularly
4. **Delete expired accounts** to free up resources

### Security

1. **Change default domain** after installation
2. **Use SSL certificates** for secure connections
3. **Monitor access logs** for suspicious activity
4. **Keep system updated** regularly

### Performance

1. **Monitor resource usage** (CPU, RAM, bandwidth)
2. **Limit concurrent connections** if needed
3. **Regularly clean up** old account files
4. **Backup configurations** regularly

## Troubleshooting

### Common Issues

#### Menu Not Responding
```bash
# Kill any stuck processes
pkill -f menu.sh

# Restart menu
source /usr/local/bin/vpn/menu.sh
```

#### Account Creation Failed
```bash
# Check permissions
ls -la /usr/local/bin/vpn/

# Check disk space
df -h

# Check system resources
free -h
```

#### Web Interface Not Accessible
```bash
# Check nginx status
systemctl status nginx

# Check port 80
netstat -tuln | grep :80

# Restart nginx
systemctl restart nginx
```

### Error Messages

#### "Permission Denied"
```bash
chmod +x /usr/local/bin/vpn/*.sh
```

#### "Command Not Found"
```bash
# Reload bashrc
source ~/.bashrc

# Or run directly
source /usr/local/bin/vpn/menu.sh
```

#### "Service Failed"
```bash
# Check service logs
journalctl -u nginx
journalctl -u dropbear
```

## Support

For additional support:

1. Check the troubleshooting section
2. Review log files for errors
3. Ensure system meets requirements
4. Contact support with detailed information

## Tips and Tricks

### Quick Commands

```bash
# Quick account creation
echo "username" | source /usr/local/bin/vpn/ssh.sh

# Check all ports at once
source /usr/local/bin/vpn/cekport.sh

# View system info only
source /usr/local/bin/vpn/utils.sh && show_system_info
```

### Automation

You can automate account creation by modifying the scripts or creating wrapper scripts for your specific needs.

### Customization

All scripts can be customized by editing the files in `/usr/local/bin/vpn/`. Remember to backup before making changes.