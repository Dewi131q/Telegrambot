#!/bin/bash

# VPN Script Utils
# Collection of utility functions

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Get public IP
get_public_ip() {
    local ip
    ip=$(curl -s https://api.ipify.org 2>/dev/null)
    if [[ -z "$ip" ]]; then
        ip=$(curl -s https://icanhazip.com 2>/dev/null)
    fi
    if [[ -z "$ip" ]]; then
        ip=$(curl -s https://ipecho.net/plain 2>/dev/null)
    fi
    echo "$ip"
}

# Get private IP
get_private_ip() {
    ip route get 8.8.8.8 | awk 'NR==1 {print $7}'
}

# Get RAM information
get_ram_info() {
    local total_ram used_ram free_ram
    total_ram=$(free -m | awk 'NR==2{printf "%.0f", $2}')
    used_ram=$(free -m | awk 'NR==2{printf "%.0f", $3}')
    free_ram=$(free -m | awk 'NR==2{printf "%.0f", $4}')
    
    echo "Total: ${total_ram}MB | Used: ${used_ram}MB | Free: ${free_ram}MB"
}

# Get CPU cores
get_cpu_cores() {
    nproc
}

# Get CPU usage
get_cpu_usage() {
    top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}'
}

# Get system uptime
get_uptime() {
    uptime -p | sed 's/up //'
}

# Get OS information
get_os_info() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "$PRETTY_NAME"
    elif [[ -f /etc/debian_version ]]; then
        echo "Debian $(cat /etc/debian_version)"
    else
        echo "Unknown OS"
    fi
}

# Get kernel version
get_kernel_version() {
    uname -r
}

# Check service status
check_service_status() {
    local service=$1
    if systemctl is-active --quiet "$service"; then
        echo -e "${GREEN}●${NC} $service"
    else
        echo -e "${RED}●${NC} $service"
    fi
}

# Get domain from file
get_domain() {
    if [[ -f /etc/vpn-script/domain.txt ]]; then
        cat /etc/vpn-script/domain.txt
    else
        get_public_ip
    fi
}

# Get banner if exists
get_banner() {
    if [[ -f /etc/vpn-script/banner.txt ]]; then
        cat /etc/vpn-script/banner.txt
    else
        echo "VPN Server"
    fi
}

# Check if port is open
check_port() {
    local port=$1
    local protocol=${2:-tcp}
    
    if [[ "$protocol" == "tcp" ]]; then
        if netstat -tuln | grep ":$port " >/dev/null; then
            echo -e "${GREEN}✓${NC}"
        else
            echo -e "${RED}✗${NC}"
        fi
    fi
}

# Get network interface
get_network_interface() {
    ip route | grep default | awk '{print $5}' | head -n1
}

# Get total accounts for each service
get_ssh_count() {
    if [[ -f /etc/vpn-script/akun/ssh_users.txt ]]; then
        wc -l < /etc/vpn-script/akun/ssh_users.txt
    else
        echo "0"
    fi
}

get_vless_count() {
    if [[ -f /etc/vpn-script/config/vless.json ]]; then
        jq '.inbounds[0].settings.clients | length' /etc/vpn-script/config/vless.json 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

get_vmess_count() {
    if [[ -f /etc/vpn-script/config/vmess.json ]]; then
        jq '.inbounds[0].settings.clients | length' /etc/vpn-script/config/vmess.json 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

get_trojan_count() {
    if [[ -f /etc/vpn-script/config/trojan.json ]]; then
        jq '.inbounds[0].settings.clients | length' /etc/vpn-script/config/trojan.json 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# Format bytes to human readable
format_bytes() {
    local bytes=$1
    if [[ $bytes -ge 1073741824 ]]; then
        printf "%.2f GB" $(echo "scale=2; $bytes/1073741824" | bc)
    elif [[ $bytes -ge 1048576 ]]; then
        printf "%.2f MB" $(echo "scale=2; $bytes/1048576" | bc)
    elif [[ $bytes -ge 1024 ]]; then
        printf "%.2f KB" $(echo "scale=2; $bytes/1024" | bc)
    else
        printf "%d B" $bytes
    fi
}

# Get disk usage
get_disk_usage() {
    df -h / | awk 'NR==2{print $3"/"$2" ("$5")"}'
}

# Generate random string
generate_random_string() {
    local length=${1:-8}
    tr -dc A-Za-z0-9 </dev/urandom | head -c $length
}

# Generate UUID
generate_uuid() {
    if command -v uuidgen >/dev/null; then
        uuidgen
    else
        cat /proc/sys/kernel/random/uuid
    fi
}

# Validate domain format
validate_domain() {
    local domain=$1
    if [[ $domain =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Validate IP format
validate_ip() {
    local ip=$1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Check if user exists
user_exists() {
    local username=$1
    if id "$username" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Get expiry date in format
get_expiry_date() {
    local days=$1
    date -d "+$days days" "+%Y-%m-%d"
}

# Check if date has expired
is_expired() {
    local expiry_date=$1
    local current_date=$(date "+%Y-%m-%d")
    
    if [[ "$current_date" > "$expiry_date" ]]; then
        return 0  # Expired
    else
        return 1  # Not expired
    fi
}

# Calculate days until expiry
days_until_expiry() {
    local expiry_date=$1
    local current_date=$(date "+%Y-%m-%d")
    local expiry_timestamp=$(date -d "$expiry_date" +%s)
    local current_timestamp=$(date -d "$current_date" +%s)
    local diff_seconds=$((expiry_timestamp - current_timestamp))
    local diff_days=$((diff_seconds / 86400))
    
    echo $diff_days
}

# Print system information
print_system_info() {
    local domain=$(get_domain)
    local public_ip=$(get_public_ip)
    local private_ip=$(get_private_ip)
    local ram_info=$(get_ram_info)
    local cpu_cores=$(get_cpu_cores)
    local cpu_usage=$(get_cpu_usage)
    local uptime=$(get_uptime)
    local os_info=$(get_os_info)
    local disk_usage=$(get_disk_usage)
    
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}           SYSTEM INFORMATION${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "Domain        : ${GREEN}$domain${NC}"
    echo -e "Public IP     : ${GREEN}$public_ip${NC}"
    echo -e "Private IP    : ${GREEN}$private_ip${NC}"
    echo -e "OS            : ${GREEN}$os_info${NC}"
    echo -e "RAM           : ${GREEN}$ram_info${NC}"
    echo -e "CPU Cores     : ${GREEN}$cpu_cores${NC}"
    echo -e "CPU Usage     : ${GREEN}$cpu_usage%${NC}"
    echo -e "Disk Usage    : ${GREEN}$disk_usage${NC}"
    echo -e "Uptime        : ${GREEN}$uptime${NC}"
    echo -e "${CYAN}========================================${NC}"
}

# Print service status
print_service_status() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}           SERVICE STATUS${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "SSH (Port 22)     : $(check_service_status ssh)"
    echo -e "Dropbear (143)    : $(check_service_status dropbear)"
    echo -e "Nginx (80/443)    : $(check_service_status nginx)"
    echo -e "Xray-core         : $(check_service_status xray)"
    echo -e "${CYAN}========================================${NC}"
}

# Print port status
print_port_status() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}            PORT STATUS${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "SSH (22)          : $(check_port 22)"
    echo -e "Dropbear (143)    : $(check_port 143)"
    echo -e "HTTP (80)         : $(check_port 80)"
    echo -e "HTTPS (443)       : $(check_port 443)"
    echo -e "VLESS (8080)      : $(check_port 8080)"
    echo -e "VMess (8443)      : $(check_port 8443)"
    echo -e "Trojan (2096)     : $(check_port 2096)"
    echo -e "WebSocket (10000) : $(check_port 10000)"
    echo -e "${CYAN}========================================${NC}"
}

# Print account statistics
print_account_stats() {
    local ssh_count=$(get_ssh_count)
    local vless_count=$(get_vless_count)
    local vmess_count=$(get_vmess_count)
    local trojan_count=$(get_trojan_count)
    
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}         ACCOUNT STATISTICS${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "SSH Accounts      : ${GREEN}$ssh_count${NC}"
    echo -e "VLESS Accounts    : ${GREEN}$vless_count${NC}"
    echo -e "VMess Accounts    : ${GREEN}$vmess_count${NC}"
    echo -e "Trojan Accounts   : ${GREEN}$trojan_count${NC}"
    echo -e "${CYAN}========================================${NC}"
}

# Print complete system status
print_complete_status() {
    clear
    echo -e "${PURPLE}$(get_banner)${NC}"
    echo ""
    print_system_info
    echo ""
    print_service_status
    echo ""
    print_account_stats
}

# Log function
log_activity() {
    local message=$1
    local logfile="/etc/vpn-script/log/activity.log"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "[$timestamp] $message" >> "$logfile"
}

# Check if script is run as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}[ERROR]${NC} Script ini harus dijalankan sebagai root!"
        exit 1
    fi
}

# Restart services
restart_services() {
    systemctl restart xray
    systemctl restart nginx
    systemctl restart dropbear
    echo -e "${GREEN}[INFO]${NC} Semua service berhasil direstart!"
}