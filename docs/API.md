# API Documentation

## Overview

This document describes the API endpoints and functions available in the VPN Auto Install Script.

## Functions

### System Information Functions

#### `get_ip()`
Returns the public IP address of the server.

**Returns:**
- `string` - Public IP address

**Example:**
```bash
IP=$(get_ip)
echo "Server IP: $IP"
```

#### `get_ram()`
Returns the total RAM of the server.

**Returns:**
- `string` - RAM size in human-readable format

**Example:**
```bash
RAM=$(get_ram)
echo "Server RAM: $RAM"
```

#### `get_core()`
Returns the number of CPU cores.

**Returns:**
- `integer` - Number of CPU cores

**Example:**
```bash
CORES=$(get_core)
echo "CPU Cores: $CORES"
```

#### `get_domain()`
Returns the configured domain name.

**Returns:**
- `string` - Domain name or "Not set"

**Example:**
```bash
DOMAIN=$(get_domain)
echo "Domain: $DOMAIN"
```

### Service Management Functions

#### `check_service(service_name)`
Checks if a service is running.

**Parameters:**
- `service_name` (string) - Name of the service to check

**Returns:**
- `string` - "✓" if running, "✗" if not running

**Example:**
```bash
STATUS=$(check_service nginx)
echo "Nginx status: $STATUS"
```

### Display Functions

#### `show_banner()`
Displays the application banner.

**Example:**
```bash
show_banner
```

#### `show_system_info()`
Displays system information including IP, RAM, CPU, Domain.

**Example:**
```bash
show_system_info
```

#### `show_active_services()`
Displays the status of active services.

**Example:**
```bash
show_active_services
```

## Account Creation Functions

### SSH Account Creation

#### `create_ssh_account()`
Creates a new SSH account with the following parameters:

**Input Parameters:**
- `username` (string) - Username for the account
- `password` (string) - Password for the account
- `duration` (integer) - Account duration in days
- `iplimit` (integer) - IP limit for the account
- `quota` (integer) - Data quota in GB

**Output:**
- Creates user account in system
- Sets account expiration
- Generates account file in `/home/vps/public_html/akun/`

**Example:**
```bash
# This function is called interactively
create_ssh_account
```

### VLESS Account Creation

#### `create_vless_account()`
Creates a new VLESS account.

**Input Parameters:**
- `username` (string) - Username for the account
- `duration` (integer) - Account duration in days

**Output:**
- Generates UUID automatically
- Creates JSON config in `/usr/local/bin/vpn/config/`
- Generates account file in `/home/vps/public_html/akun/`

**Example:**
```bash
# This function is called interactively
create_vless_account
```

### VMess Account Creation

#### `create_vmess_account()`
Creates a new VMess account.

**Input Parameters:**
- `username` (string) - Username for the account
- `duration` (integer) - Account duration in days

**Output:**
- Generates UUID automatically
- Creates JSON config in `/usr/local/bin/vpn/config/`
- Generates account file in `/home/vps/public_html/akun/`

**Example:**
```bash
# This function is called interactively
create_vmess_account
```

### Trojan Account Creation

#### `create_trojan_account()`
Creates a new Trojan account.

**Input Parameters:**
- `username` (string) - Username for the account
- `duration` (integer) - Account duration in days

**Output:**
- Generates random password automatically
- Creates JSON config in `/usr/local/bin/vpn/config/`
- Generates account file in `/home/vps/public_html/akun/`

**Example:**
```bash
# This function is called interactively
create_trojan_account
```

## Configuration Functions

### Domain Management

#### `change_domain()`
Changes the server domain.

**Input Parameters:**
- `new_domain` (string) - New domain name

**Output:**
- Updates `/etc/xray/domain` file

**Example:**
```bash
# This function is called interactively
change_domain
```

### Banner Management

#### `change_banner()`
Changes the server banner.

**Input Parameters:**
- `banner_text` (string) - New banner text (multi-line)

**Output:**
- Updates `/etc/issue.net` file

**Example:**
```bash
# This function is called interactively
change_banner
```

## Monitoring Functions

### Port Checking

#### `check_ports()`
Checks the status of common ports.

**Output:**
- Displays status of ports: 22, 80, 443, 8080, 8443, 8880, 2083, 2087, 2096, 9443
- Shows detailed port information

**Example:**
```bash
# This function is called interactively
check_ports
```

## File Structure

### Configuration Files
- `/etc/xray/domain` - Server domain configuration
- `/etc/issue.net` - Server banner configuration
- `/usr/local/bin/vpn/config/` - Protocol configuration files

### Account Files
- `/home/vps/public_html/akun/` - Account detail files

### Log Files
- `/var/log/nginx/` - Nginx logs
- `/var/log/xray/` - XRAY logs
- `/var/log/syslog` - System logs

## Error Handling

All functions include error handling for:
- Invalid input parameters
- File permission issues
- Service status checks
- Network connectivity issues

## Color Codes

The script uses ANSI color codes for output:
- `RED` - Error messages
- `GREEN` - Success messages
- `YELLOW` - Warning messages
- `BLUE` - Information messages
- `CYAN` - Menu headers
- `PURPLE` - Special formatting

## Security Considerations

- All passwords are properly hashed
- File permissions are set correctly
- Input validation is implemented
- Sensitive data is not logged
- Error messages don't expose system information