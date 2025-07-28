#!/bin/bash

# ==========================================
# VPN Server Monitoring Script
# ==========================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Source utils
source /usr/local/bin/vpn/utils.sh

# Show banner
show_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    VPN SERVER MONITORING                     ║"
    echo "║                        Version 1.0                           ║"
    echo "║                    Author: VPN Script Creator                 ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Get system uptime
get_uptime() {
    uptime -p | sed 's/up //'
}

# Get CPU usage
get_cpu_usage() {
    top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//'
}

# Get memory usage
get_memory_usage() {
    free | awk '/Mem:/ {printf "%.1f", $3/$2 * 100.0}'
}

# Get disk usage
get_disk_usage() {
    df / | awk 'NR==2 {print $5}' | sed 's/%//'
}

# Get network connections
get_connections() {
    netstat -an | grep ESTABLISHED | wc -l
}

# Get active users
get_active_users() {
    who | wc -l
}

# Get load average
get_load_average() {
    uptime | awk -F'load average:' '{print $2}' | sed 's/,//g'
}

# Monitor system resources
monitor_system() {
    clear
    show_banner
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                      SYSTEM MONITORING                       ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # System information
    echo -e "${YELLOW}═══════════════════════ SYSTEM INFO ═══════════════════════${NC}"
    echo -e "${BLUE}Hostname    : ${GREEN}$(hostname)${NC}"
    echo -e "${BLUE}IP Address  : ${GREEN}$(get_ip)${NC}"
    echo -e "${BLUE}Domain      : ${GREEN}$(get_domain)${NC}"
    echo -e "${BLUE}Uptime      : ${GREEN}$(get_uptime)${NC}"
    echo -e "${BLUE}Load Average: ${GREEN}$(get_load_average)${NC}"
    echo -e "${BLUE}Active Users: ${GREEN}$(get_active_users)${NC}"
    echo -e "${BLUE}Connections : ${GREEN}$(get_connections)${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Resource usage
    echo -e "${YELLOW}═══════════════════════ RESOURCE USAGE ══════════════════════${NC}"
    local cpu_usage=$(get_cpu_usage)
    local mem_usage=$(get_memory_usage)
    local disk_usage=$(get_disk_usage)
    
    # CPU usage with color
    if (( $(echo "$cpu_usage < 50" | bc -l) )); then
        echo -e "${BLUE}CPU Usage   : ${GREEN}${cpu_usage}%${NC}"
    elif (( $(echo "$cpu_usage < 80" | bc -l) )); then
        echo -e "${BLUE}CPU Usage   : ${YELLOW}${cpu_usage}%${NC}"
    else
        echo -e "${BLUE}CPU Usage   : ${RED}${cpu_usage}%${NC}"
    fi
    
    # Memory usage with color
    if (( $(echo "$mem_usage < 70" | bc -l) )); then
        echo -e "${BLUE}Memory Usage: ${GREEN}${mem_usage}%${NC}"
    elif (( $(echo "$mem_usage < 90" | bc -l) )); then
        echo -e "${BLUE}Memory Usage: ${YELLOW}${mem_usage}%${NC}"
    else
        echo -e "${BLUE}Memory Usage: ${RED}${mem_usage}%${NC}"
    fi
    
    # Disk usage with color
    if (( disk_usage < 70 )); then
        echo -e "${BLUE}Disk Usage  : ${GREEN}${disk_usage}%${NC}"
    elif (( disk_usage < 90 )); then
        echo -e "${BLUE}Disk Usage  : ${YELLOW}${disk_usage}%${NC}"
    else
        echo -e "${BLUE}Disk Usage  : ${RED}${disk_usage}%${NC}"
    fi
    
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Service status
    echo -e "${YELLOW}═══════════════════════ SERVICE STATUS ══════════════════════${NC}"
    local services=("nginx" "dropbear" "xray")
    
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service"; then
            echo -e "${BLUE}$service: ${GREEN}✓ Running${NC}"
        else
            echo -e "${BLUE}$service: ${RED}✗ Stopped${NC}"
        fi
    done
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Port status
    echo -e "${YELLOW}═══════════════════════ PORT STATUS ════════════════════════${NC}"
    local ports=(22 80 443 8080 8443)
    
    for port in "${ports[@]}"; do
        if netstat -tuln | grep -q ":$port "; then
            echo -e "${BLUE}Port $port: ${GREEN}✓ Open${NC}"
        else
            echo -e "${BLUE}Port $port: ${RED}✗ Closed${NC}"
        fi
    done
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    read -p "Press Enter to continue..."
    source /usr/local/bin/vpn/menu.sh
}

# Monitor logs
monitor_logs() {
    clear
    show_banner
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                        LOG MONITORING                         ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${YELLOW}Select log to monitor:${NC}"
    echo ""
    echo -e "${BLUE}[1] System Log (syslog)${NC}"
    echo -e "${BLUE}[2] Nginx Access Log${NC}"
    echo -e "${BLUE}[3] Nginx Error Log${NC}"
    echo -e "${BLUE}[4] SSH Auth Log${NC}"
    echo -e "${BLUE}[5] Back to Monitoring Menu${NC}"
    echo ""
    read -p "Select option [1-5]: " choice
    
    case $choice in
        1) tail -f /var/log/syslog ;;
        2) tail -f /var/log/nginx/access.log ;;
        3) tail -f /var/log/nginx/error.log ;;
        4) tail -f /var/log/auth.log ;;
        5) source /usr/local/bin/vpn/menu.sh ;;
        *) echo -e "${RED}Invalid option!${NC}"; sleep 2; monitor_logs ;;
    esac
}

# Monitor connections
monitor_connections() {
    clear
    show_banner
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                     CONNECTION MONITORING                     ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${YELLOW}Active Network Connections:${NC}"
    echo ""
    
    # Show all active connections
    netstat -tuln | grep -E ':(22|80|443|8080|8443)' | while read -r line; do
        echo -e "${BLUE}$line${NC}"
    done
    
    echo ""
    echo -e "${YELLOW}Established Connections:${NC}"
    echo ""
    
    # Show established connections
    netstat -an | grep ESTABLISHED | head -10 | while read -r line; do
        echo -e "${GREEN}$line${NC}"
    done
    
    echo ""
    echo -e "${YELLOW}SSH Connections:${NC}"
    echo ""
    
    # Show SSH connections
    who | while read -r line; do
        echo -e "${CYAN}$line${NC}"
    done
    
    echo ""
    read -p "Press Enter to continue..."
    source /usr/local/bin/vpn/menu.sh
}

# Monitor processes
monitor_processes() {
    clear
    show_banner
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                      PROCESS MONITORING                      ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${YELLOW}Top Processes by CPU Usage:${NC}"
    echo ""
    
    # Show top processes by CPU
    ps aux --sort=-%cpu | head -10 | while read -r line; do
        echo -e "${BLUE}$line${NC}"
    done
    
    echo ""
    echo -e "${YELLOW}Top Processes by Memory Usage:${NC}"
    echo ""
    
    # Show top processes by memory
    ps aux --sort=-%mem | head -10 | while read -r line; do
        echo -e "${BLUE}$line${NC}"
    done
    
    echo ""
    echo -e "${YELLOW}VPN Related Processes:${NC}"
    echo ""
    
    # Show VPN related processes
    ps aux | grep -E "(nginx|dropbear|xray)" | grep -v grep | while read -r line; do
        echo -e "${GREEN}$line${NC}"
    done
    
    echo ""
    read -p "Press Enter to continue..."
    source /usr/local/bin/vpn/menu.sh
}

# Generate report
generate_report() {
    clear
    show_banner
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                      GENERATE REPORT                          ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Create report directory
    mkdir -p /home/vps/public_html/reports
    
    # Generate report filename
    REPORT_FILE="/home/vps/public_html/reports/vpn_report_$(date +%Y%m%d_%H%M%S).txt"
    
    echo -e "${YELLOW}Generating system report...${NC}"
    echo ""
    
    # Generate comprehensive report
    cat > "$REPORT_FILE" << EOF
VPN Server System Report
========================
Generated: $(date)
Hostname: $(hostname)
IP Address: $(get_ip)
Domain: $(get_domain)

System Information
------------------
Uptime: $(get_uptime)
Load Average: $(get_load_average)
CPU Usage: $(get_cpu_usage)%
Memory Usage: $(get_memory_usage)%
Disk Usage: $(get_disk_usage)%
Active Users: $(get_active_users)
Active Connections: $(get_connections)

Service Status
--------------
EOF
    
    # Add service status to report
    local services=("nginx" "dropbear" "xray")
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service"; then
            echo "$service: Running" >> "$REPORT_FILE"
        else
            echo "$service: Stopped" >> "$REPORT_FILE"
        fi
    done
    
    # Add port status to report
    echo "" >> "$REPORT_FILE"
    echo "Port Status" >> "$REPORT_FILE"
    echo "-----------" >> "$REPORT_FILE"
    
    local ports=(22 80 443 8080 8443)
    for port in "${ports[@]}"; do
        if netstat -tuln | grep -q ":$port "; then
            echo "Port $port: Open" >> "$REPORT_FILE"
        else
            echo "Port $port: Closed" >> "$REPORT_FILE"
        fi
    done
    
    # Add recent log entries
    echo "" >> "$REPORT_FILE"
    echo "Recent System Logs" >> "$REPORT_FILE"
    echo "------------------" >> "$REPORT_FILE"
    tail -20 /var/log/syslog >> "$REPORT_FILE"
    
    echo -e "${GREEN}✓ Report generated successfully!${NC}"
    echo -e "${YELLOW}Report file: $REPORT_FILE${NC}"
    echo -e "${BLUE}Access via web: http://$(get_ip)/reports/$(basename "$REPORT_FILE")${NC}"
    echo ""
    read -p "Press Enter to continue..."
    source /usr/local/bin/vpn/menu.sh
}

# Main menu
main_menu() {
    clear
    show_banner
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    MONITORING MENU                            ║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║  [1] System Monitoring                                        ║${NC}"
    echo -e "${CYAN}║  [2] Log Monitoring                                           ║${NC}"
    echo -e "${CYAN}║  [3] Connection Monitoring                                    ║${NC}"
    echo -e "${CYAN}║  [4] Process Monitoring                                       ║${NC}"
    echo -e "${CYAN}║  [5] Generate Report                                          ║${NC}"
    echo -e "${CYAN}║  [6] Back to Main Menu                                        ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    read -p "Select option [1-6]: " choice
    
    case $choice in
        1) monitor_system ;;
        2) monitor_logs ;;
        3) monitor_connections ;;
        4) monitor_processes ;;
        5) generate_report ;;
        6) source /usr/local/bin/vpn/menu.sh ;;
        *) echo -e "${RED}Invalid option!${NC}"; sleep 2; main_menu ;;
    esac
}

# Start menu
main_menu