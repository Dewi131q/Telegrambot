#!/bin/bash

# Port Checker
# Created by VPN-Installer

# Source utility functions
source /usr/local/bin/vpn-script/utils.sh

# Check if running as root
check_root

# Default ports
declare -A DEFAULT_PORTS=(
    ["SSH"]="22"
    ["Dropbear"]="143"
    ["HTTP"]="80"
    ["HTTPS"]="443"
    ["VLESS"]="8080"
    ["VMess"]="8443"
    ["Trojan"]="2096"
    ["WebSocket"]="10000"
)

# Check single port
check_single_port() {
    local port=$1
    local protocol=${2:-tcp}
    
    if netstat -tuln 2>/dev/null | grep -q ":$port "; then
        echo -e "${GREEN}✓ OPEN${NC}"
    else
        echo -e "${RED}✗ CLOSED${NC}"
    fi
}

# Get process using port
get_port_process() {
    local port=$1
    local protocol=${2:-tcp}
    
    if command -v lsof >/dev/null; then
        lsof -ti:$port 2>/dev/null | head -1 | xargs -r ps -p | tail -1 | awk '{print $4}'
    elif command -v netstat >/dev/null; then
        netstat -tlnp 2>/dev/null | grep ":$port " | awk '{print $7}' | cut -d'/' -f2 | head -1
    else
        echo "N/A"
    fi
}

# Check all default ports
check_all_ports() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}           PORT STATUS CHECK${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    
    printf "%-15s %-8s %-10s %-15s\n" "Service" "Port" "Status" "Process"
    echo "-------------------------------------------------------"
    
    for service in "${!DEFAULT_PORTS[@]}"; do
        port=${DEFAULT_PORTS[$service]}
        status=$(check_single_port "$port")
        process=$(get_port_process "$port")
        
        if [[ -z "$process" ]]; then
            process="N/A"
        fi
        
        printf "%-15s %-8s %-10s %-15s\n" "$service" "$port" "$status" "$process"
    done
    
    echo "-------------------------------------------------------"
    echo ""
    
    # Additional information
    echo -e "${YELLOW}Legend:${NC}"
    echo -e "${GREEN}✓ OPEN${NC}   - Port is listening and accepting connections"
    echo -e "${RED}✗ CLOSED${NC} - Port is not listening"
    echo ""
}

# Check specific port
check_specific_port() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}        CHECK SPECIFIC PORT${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    
    while true; do
        read -p "Enter port number to check: " port
        
        if [[ ! "$port" =~ ^[0-9]+$ ]] || [[ "$port" -lt 1 ]] || [[ "$port" -gt 65535 ]]; then
            echo -e "${RED}[ERROR]${NC} Invalid port number! Must be between 1-65535."
            continue
        fi
        
        break
    done
    
    echo ""
    echo -e "${YELLOW}Checking port $port...${NC}"
    echo ""
    
    # Check if port is open
    if netstat -tuln 2>/dev/null | grep -q ":$port "; then
        echo -e "Port Status: ${GREEN}OPEN${NC}"
        
        # Get detailed information
        if command -v netstat >/dev/null; then
            echo ""
            echo -e "${YELLOW}Detailed Information:${NC}"
            netstat -tuln 2>/dev/null | grep ":$port " | while read line; do
                proto=$(echo "$line" | awk '{print $1}')
                addr=$(echo "$line" | awk '{print $4}')
                state=$(echo "$line" | awk '{print $6}')
                
                echo -e "Protocol: $proto | Address: $addr | State: $state"
            done
        fi
        
        # Get process information
        process=$(get_port_process "$port")
        if [[ -n "$process" && "$process" != "N/A" ]]; then
            echo -e "Process: ${GREEN}$process${NC}"
        fi
        
        # Check with lsof if available
        if command -v lsof >/dev/null; then
            echo ""
            echo -e "${YELLOW}Process Details:${NC}"
            lsof -i:$port 2>/dev/null || echo "No detailed process information available"
        fi
        
    else
        echo -e "Port Status: ${RED}CLOSED${NC}"
        echo ""
        echo -e "${YELLOW}Port $port is not listening or not accessible.${NC}"
    fi
    
    echo ""
}

# Check port connectivity
check_port_connectivity() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}       PORT CONNECTIVITY TEST${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    
    local public_ip=$(get_public_ip)
    
    echo -e "Testing external connectivity to your server ports..."
    echo -e "Server IP: ${GREEN}$public_ip${NC}"
    echo ""
    
    echo -e "${YELLOW}Testing common VPN ports:${NC}"
    echo ""
    
    for service in "${!DEFAULT_PORTS[@]}"; do
        port=${DEFAULT_PORTS[$service]}
        
        echo -ne "Testing $service (port $port)... "
        
        # Use timeout and nc to test connectivity
        if timeout 5 bash -c "</dev/tcp/$public_ip/$port" 2>/dev/null; then
            echo -e "${GREEN}✓ Reachable${NC}"
        else
            echo -e "${RED}✗ Unreachable${NC}"
        fi
    done
    
    echo ""
    echo -e "${YELLOW}Note:${NC} External connectivity depends on:"
    echo -e "- Firewall settings"
    echo -e "- Network configuration"
    echo -e "- Service status"
    echo -e "- Provider restrictions"
    echo ""
}

# Show firewall status
show_firewall_status() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}          FIREWALL STATUS${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    
    # Check iptables
    if command -v iptables >/dev/null; then
        echo -e "${YELLOW}IPTables Rules:${NC}"
        echo ""
        
        # Show INPUT rules for our ports
        echo -e "${CYAN}INPUT Rules (Incoming Traffic):${NC}"
        iptables -L INPUT -n --line-numbers | grep -E "(22|143|80|443|8080|8443|2096|10000)" || echo "No specific rules found for VPN ports"
        echo ""
        
        # Show general policy
        echo -e "${CYAN}Default Policies:${NC}"
        iptables -L | grep "Chain" | grep "policy"
        echo ""
    else
        echo -e "${YELLOW}[INFO]${NC} iptables not found"
    fi
    
    # Check ufw if available
    if command -v ufw >/dev/null; then
        echo -e "${YELLOW}UFW Status:${NC}"
        ufw status verbose 2>/dev/null || echo "UFW not configured"
        echo ""
    fi
    
    # Check fail2ban if available
    if command -v fail2ban-client >/dev/null; then
        echo -e "${YELLOW}Fail2Ban Status:${NC}"
        fail2ban-client status 2>/dev/null || echo "Fail2Ban not active"
        echo ""
    fi
}

# Port scanner
port_scanner() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}           PORT SCANNER${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    
    echo -e "${YELLOW}Scanning common ports on localhost...${NC}"
    echo ""
    
    # Common ports to scan
    local common_ports=(21 22 23 25 53 80 110 143 443 993 995 8080 8443 2096 10000)
    
    echo -e "Port     Status     Service"
    echo "--------------------------------"
    
    for port in "${common_ports[@]}"; do
        if timeout 1 bash -c "</dev/tcp/127.0.0.1/$port" 2>/dev/null; then
            status="${GREEN}OPEN${NC}"
            
            # Try to identify service
            case $port in
                21) service="FTP" ;;
                22) service="SSH" ;;
                23) service="Telnet" ;;
                25) service="SMTP" ;;
                53) service="DNS" ;;
                80) service="HTTP" ;;
                110) service="POP3" ;;
                143) service="Dropbear" ;;
                443) service="HTTPS" ;;
                993) service="IMAPS" ;;
                995) service="POP3S" ;;
                8080) service="VLESS" ;;
                8443) service="VMess" ;;
                2096) service="Trojan" ;;
                10000) service="WebSocket" ;;
                *) service="Unknown" ;;
            esac
        else
            status="${RED}CLOSED${NC}"
            service=""
        fi
        
        printf "%-8s %-10s %s\n" "$port" "$status" "$service"
    done
    
    echo ""
}

# Network statistics
show_network_stats() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}         NETWORK STATISTICS${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    
    # Active connections
    echo -e "${YELLOW}Active Connections Summary:${NC}"
    if command -v netstat >/dev/null; then
        echo -e "Total connections: ${GREEN}$(netstat -an | grep ESTABLISHED | wc -l)${NC}"
        echo -e "Listening ports: ${GREEN}$(netstat -tln | grep LISTEN | wc -l)${NC}"
        echo ""
        
        echo -e "${YELLOW}Connections by Service:${NC}"
        for service in "${!DEFAULT_PORTS[@]}"; do
            port=${DEFAULT_PORTS[$service]}
            count=$(netstat -an | grep ":$port " | grep ESTABLISHED | wc -l)
            if [[ $count -gt 0 ]]; then
                echo -e "$service (port $port): ${GREEN}$count${NC} connections"
            fi
        done
        echo ""
        
        # Top connections by IP
        echo -e "${YELLOW}Top 5 Connected IPs:${NC}"
        netstat -an | grep ESTABLISHED | awk '{print $5}' | cut -d':' -f1 | sort | uniq -c | sort -nr | head -5 | while read count ip; do
            echo -e "$ip: ${GREEN}$count${NC} connections"
        done
    else
        echo -e "${RED}[ERROR]${NC} netstat not available"
    fi
    
    echo ""
}

# Service status check
check_service_status() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}          SERVICE STATUS${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    
    # Define services to check
    local services=("ssh" "dropbear" "nginx" "xray")
    
    printf "%-15s %-10s %-15s\n" "Service" "Status" "Port(s)"
    echo "----------------------------------------"
    
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service"; then
            status="${GREEN}Active${NC}"
        else
            status="${RED}Inactive${NC}"
        fi
        
        # Get ports for each service
        case $service in
            "ssh") ports="22" ;;
            "dropbear") ports="143" ;;
            "nginx") ports="80, 443" ;;
            "xray") ports="8080, 8443, 2096" ;;
            *) ports="N/A" ;;
        esac
        
        printf "%-15s %-10s %-15s\n" "$service" "$status" "$ports"
    done
    
    echo ""
    
    # Additional service information
    echo -e "${YELLOW}Detailed Service Information:${NC}"
    echo ""
    
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service"; then
            uptime=$(systemctl show "$service" --property=ActiveEnterTimestamp | cut -d'=' -f2)
            echo -e "$service: ${GREEN}Running${NC} since $uptime"
        else
            echo -e "$service: ${RED}Not running${NC}"
        fi
    done
    
    echo ""
}

# Main menu
main_menu() {
    while true; do
        clear
        echo -e "${CYAN}========================================${NC}"
        echo -e "${GREEN}           PORT CHECKER${NC}"
        echo -e "${CYAN}========================================${NC}"
        echo ""
        
        echo -e "${YELLOW}Options:${NC}"
        echo -e "[1] Check All Default Ports"
        echo -e "[2] Check Specific Port"
        echo -e "[3] Port Connectivity Test"
        echo -e "[4] Show Firewall Status"
        echo -e "[5] Port Scanner"
        echo -e "[6] Network Statistics"
        echo -e "[7] Service Status"
        echo -e "[0] Back to Main Menu"
        echo ""
        
        read -p "Choose option [0-7]: " choice
        
        case $choice in
            1)
                check_all_ports
                read -p "Press Enter to continue..."
                ;;
            2)
                check_specific_port
                read -p "Press Enter to continue..."
                ;;
            3)
                check_port_connectivity
                read -p "Press Enter to continue..."
                ;;
            4)
                show_firewall_status
                read -p "Press Enter to continue..."
                ;;
            5)
                port_scanner
                read -p "Press Enter to continue..."
                ;;
            6)
                show_network_stats
                read -p "Press Enter to continue..."
                ;;
            7)
                check_service_status
                read -p "Press Enter to continue..."
                ;;
            0)
                break
                ;;
            *)
                echo -e "${RED}[ERROR]${NC} Invalid option!"
                sleep 2
                ;;
        esac
    done
}

# Quick check function
quick_check() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}         QUICK PORT CHECK${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    
    for service in "${!DEFAULT_PORTS[@]}"; do
        port=${DEFAULT_PORTS[$service]}
        status=$(check_single_port "$port")
        echo -e "$service (port $port): $status"
    done
    
    echo ""
}

# Main function
main() {
    case "${1:-}" in
        "quick")
            quick_check
            ;;
        "all")
            check_all_ports
            read -p "Press Enter to continue..."
            ;;
        "scan")
            port_scanner
            read -p "Press Enter to continue..."
            ;;
        "services")
            check_service_status
            read -p "Press Enter to continue..."
            ;;
        "firewall")
            show_firewall_status
            read -p "Press Enter to continue..."
            ;;
        *)
            main_menu
            ;;
    esac
}

# Run main function with arguments
main "$@"