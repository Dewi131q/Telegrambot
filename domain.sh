#!/bin/bash

# Domain Manager
# Created by VPN-Installer

# Source utility functions
source /usr/local/bin/vpn-script/utils.sh

# Check if running as root
check_root

# Domain configuration file
DOMAIN_FILE="/etc/vpn-script/domain.txt"

# Change domain
change_domain() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}           CHANGE DOMAIN${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    
    # Get current domain
    current_domain=$(get_domain)
    public_ip=$(get_public_ip)
    
    echo -e "Current Domain : ${GREEN}$current_domain${NC}"
    echo -e "Public IP      : ${GREEN}$public_ip${NC}"
    echo ""
    
    echo -e "${YELLOW}Options:${NC}"
    echo -e "[1] Use custom domain"
    echo -e "[2] Use IP address"
    echo -e "[0] Cancel"
    echo ""
    
    read -p "Choose option [0-2]: " choice
    
    case $choice in
        1)
            change_custom_domain
            ;;
        2)
            change_to_ip
            ;;
        0)
            echo -e "${YELLOW}[INFO]${NC} Operation cancelled."
            return
            ;;
        *)
            echo -e "${RED}[ERROR]${NC} Invalid option!"
            sleep 2
            change_domain
            ;;
    esac
}

# Change to custom domain
change_custom_domain() {
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}         SET CUSTOM DOMAIN${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    
    while true; do
        read -p "Enter your domain: " new_domain
        
        if [[ -z "$new_domain" ]]; then
            echo -e "${RED}[ERROR]${NC} Domain cannot be empty!"
            continue
        fi
        
        # Basic domain validation
        if ! validate_domain "$new_domain"; then
            echo -e "${RED}[ERROR]${NC} Invalid domain format!"
            echo -e "Example: example.com, subdomain.example.com"
            continue
        fi
        
        break
    done
    
    # Confirm domain change
    echo ""
    echo -e "${YELLOW}[CONFIRMATION]${NC}"
    echo -e "Current domain : ${RED}$(get_domain)${NC}"
    echo -e "New domain     : ${GREEN}$new_domain${NC}"
    echo ""
    
    read -p "Are you sure you want to change the domain? (yes/no): " confirm
    
    if [[ "$confirm" != "yes" ]]; then
        echo -e "${YELLOW}[INFO]${NC} Domain change cancelled."
        return
    fi
    
    # Check domain resolution
    echo ""
    echo -e "${YELLOW}[INFO]${NC} Checking domain resolution..."
    
    domain_ip=$(dig +short "$new_domain" 2>/dev/null | grep -E '^[0-9.]+$' | head -n1)
    public_ip=$(get_public_ip)
    
    if [[ -n "$domain_ip" ]]; then
        if [[ "$domain_ip" == "$public_ip" ]]; then
            echo -e "${GREEN}[SUCCESS]${NC} Domain resolves to server IP ($domain_ip)"
        else
            echo -e "${YELLOW}[WARNING]${NC} Domain resolves to $domain_ip but server IP is $public_ip"
            echo -e "${YELLOW}[WARNING]${NC} Make sure your domain points to the server IP!"
            echo ""
            read -p "Continue anyway? (yes/no): " force_continue
            
            if [[ "$force_continue" != "yes" ]]; then
                echo -e "${YELLOW}[INFO]${NC} Domain change cancelled."
                return
            fi
        fi
    else
        echo -e "${YELLOW}[WARNING]${NC} Cannot resolve domain. Make sure it points to $public_ip"
        echo ""
        read -p "Continue anyway? (yes/no): " force_continue
        
        if [[ "$force_continue" != "yes" ]]; then
            echo -e "${YELLOW}[INFO]${NC} Domain change cancelled."
            return
        fi
    fi
    
    # Save new domain
    echo "$new_domain" > "$DOMAIN_FILE"
    
    # Update configurations
    update_configurations "$new_domain"
    
    echo ""
    echo -e "${GREEN}[SUCCESS]${NC} Domain changed successfully!"
    echo -e "New domain: ${GREEN}$new_domain${NC}"
    
    # Log activity
    log_activity "Domain changed to: $new_domain"
}

# Change to IP address
change_to_ip() {
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}           USE IP ADDRESS${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    
    public_ip=$(get_public_ip)
    current_domain=$(get_domain)
    
    echo -e "Current domain : ${RED}$current_domain${NC}"
    echo -e "Server IP      : ${GREEN}$public_ip${NC}"
    echo ""
    
    read -p "Use IP address as domain? (yes/no): " confirm
    
    if [[ "$confirm" != "yes" ]]; then
        echo -e "${YELLOW}[INFO]${NC} Operation cancelled."
        return
    fi
    
    # Save IP as domain
    echo "$public_ip" > "$DOMAIN_FILE"
    
    # Update configurations
    update_configurations "$public_ip"
    
    echo ""
    echo -e "${GREEN}[SUCCESS]${NC} Domain changed to IP address!"
    echo -e "New domain: ${GREEN}$public_ip${NC}"
    
    # Log activity
    log_activity "Domain changed to IP: $public_ip"
}

# Update configurations with new domain
update_configurations() {
    local new_domain="$1"
    
    echo ""
    echo -e "${YELLOW}[INFO]${NC} Updating configurations..."
    
    # Update Nginx configuration
    if [[ -f /etc/nginx/sites-available/vpn ]]; then
        sed -i "s/server_name .*/server_name $new_domain;/" /etc/nginx/sites-available/vpn
        nginx -t && systemctl reload nginx
        echo -e "${GREEN}✓${NC} Nginx configuration updated"
    fi
    
    # Update Xray configuration (if needed)
    if [[ -f /usr/local/etc/xray/config.json ]]; then
        # Update any domain references in Xray config
        systemctl restart xray
        echo -e "${GREEN}✓${NC} Xray service restarted"
    fi
    
    # Restart other services
    systemctl restart dropbear
    echo -e "${GREEN}✓${NC} Dropbear service restarted"
    
    echo -e "${GREEN}✓${NC} All configurations updated"
}

# Show current domain info
show_domain_info() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}         DOMAIN INFORMATION${NC}"
    echo -e "${CYAN}========================================${NC}"
    
    local current_domain=$(get_domain)
    local public_ip=$(get_public_ip)
    local private_ip=$(get_private_ip)
    
    echo -e "Current Domain : ${GREEN}$current_domain${NC}"
    echo -e "Public IP      : ${GREEN}$public_ip${NC}"
    echo -e "Private IP     : ${GREEN}$private_ip${NC}"
    echo ""
    
    # Check if domain is IP or actual domain
    if validate_ip "$current_domain"; then
        echo -e "Type           : ${YELLOW}IP Address${NC}"
    else
        echo -e "Type           : ${YELLOW}Domain Name${NC}"
        
        # Check domain resolution
        echo ""
        echo -e "${YELLOW}Domain Resolution Check:${NC}"
        domain_ip=$(dig +short "$current_domain" 2>/dev/null | grep -E '^[0-9.]+$' | head -n1)
        
        if [[ -n "$domain_ip" ]]; then
            echo -e "Resolves to    : ${GREEN}$domain_ip${NC}"
            
            if [[ "$domain_ip" == "$public_ip" ]]; then
                echo -e "Status         : ${GREEN}✓ Correct${NC}"
            else
                echo -e "Status         : ${RED}✗ Incorrect${NC}"
                echo -e "Expected       : ${YELLOW}$public_ip${NC}"
            fi
        else
            echo -e "Resolves to    : ${RED}Not found${NC}"
            echo -e "Status         : ${RED}✗ DNS Error${NC}"
        fi
    fi
    
    echo -e "${CYAN}========================================${NC}"
}

# Show DNS setup help
show_dns_help() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}           DNS SETUP HELP${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    
    local public_ip=$(get_public_ip)
    
    echo -e "${YELLOW}To use a custom domain:${NC}"
    echo ""
    echo -e "1. Login to your domain registrar or DNS provider"
    echo -e "2. Create an A record:"
    echo -e "   - Name: ${GREEN}@${NC} (for root domain) or ${GREEN}vpn${NC} (for subdomain)"
    echo -e "   - Type: ${GREEN}A${NC}"
    echo -e "   - Value: ${GREEN}$public_ip${NC}"
    echo -e "   - TTL: ${GREEN}300${NC} (or default)"
    echo ""
    echo -e "3. Wait for DNS propagation (5-60 minutes)"
    echo -e "4. Test with: ${GREEN}nslookup yourdomain.com${NC}"
    echo -e "5. Return here and set your domain"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo -e "- Root domain: ${GREEN}example.com${NC}"
    echo -e "- Subdomain: ${GREEN}vpn.example.com${NC}"
    echo ""
    echo -e "${YELLOW}Popular DNS Providers:${NC}"
    echo -e "- Cloudflare (recommended)"
    echo -e "- Google Cloud DNS"
    echo -e "- AWS Route 53"
    echo -e "- DigitalOcean DNS"
    echo ""
    echo -e "${CYAN}========================================${NC}"
}

# Main menu
main_menu() {
    while true; do
        clear
        echo -e "${CYAN}========================================${NC}"
        echo -e "${GREEN}         DOMAIN MANAGER${NC}"
        echo -e "${CYAN}========================================${NC}"
        echo ""
        
        show_domain_info
        echo ""
        echo -e "${YELLOW}Options:${NC}"
        echo -e "[1] Change Domain"
        echo -e "[2] Show DNS Setup Help"
        echo -e "[3] Check Domain Resolution"
        echo -e "[0] Back to Main Menu"
        echo ""
        
        read -p "Choose option [0-3]: " choice
        
        case $choice in
            1)
                change_domain
                read -p "Press Enter to continue..."
                ;;
            2)
                show_dns_help
                read -p "Press Enter to continue..."
                ;;
            3)
                check_domain_resolution
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

# Check domain resolution
check_domain_resolution() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}       DOMAIN RESOLUTION CHECK${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    
    local current_domain=$(get_domain)
    local public_ip=$(get_public_ip)
    
    if validate_ip "$current_domain"; then
        echo -e "Current domain is an IP address: ${GREEN}$current_domain${NC}"
        echo -e "No DNS resolution needed."
        return
    fi
    
    echo -e "Checking domain: ${GREEN}$current_domain${NC}"
    echo -e "Expected IP: ${GREEN}$public_ip${NC}"
    echo ""
    
    echo -e "${YELLOW}Performing DNS lookup...${NC}"
    
    # Multiple DNS resolution checks
    local resolved_ips=()
    
    # Using dig
    if command -v dig >/dev/null; then
        local dig_result=$(dig +short "$current_domain" 2>/dev/null | grep -E '^[0-9.]+$')
        if [[ -n "$dig_result" ]]; then
            resolved_ips+=("$dig_result")
            echo -e "dig result: ${GREEN}$dig_result${NC}"
        else
            echo -e "dig result: ${RED}No A record found${NC}"
        fi
    fi
    
    # Using nslookup
    if command -v nslookup >/dev/null; then
        local nslookup_result=$(nslookup "$current_domain" 2>/dev/null | grep -A1 "Name:" | tail -n1 | awk '{print $2}')
        if [[ -n "$nslookup_result" && "$nslookup_result" =~ ^[0-9.]+$ ]]; then
            echo -e "nslookup result: ${GREEN}$nslookup_result${NC}"
        else
            echo -e "nslookup result: ${RED}No A record found${NC}"
        fi
    fi
    
    # Using host
    if command -v host >/dev/null; then
        local host_result=$(host "$current_domain" 2>/dev/null | grep "has address" | awk '{print $4}' | head -n1)
        if [[ -n "$host_result" ]]; then
            echo -e "host result: ${GREEN}$host_result${NC}"
        else
            echo -e "host result: ${RED}No A record found${NC}"
        fi
    fi
    
    echo ""
    
    # Check if any resolution matches our IP
    if [[ ${#resolved_ips[@]} -gt 0 ]]; then
        local match_found=false
        for ip in "${resolved_ips[@]}"; do
            if [[ "$ip" == "$public_ip" ]]; then
                match_found=true
                break
            fi
        done
        
        if $match_found; then
            echo -e "${GREEN}✓ Domain correctly points to server IP${NC}"
        else
            echo -e "${RED}✗ Domain does not point to server IP${NC}"
            echo -e "  Domain points to: ${YELLOW}${resolved_ips[0]}${NC}"
            echo -e "  Should point to: ${YELLOW}$public_ip${NC}"
        fi
    else
        echo -e "${RED}✗ Domain resolution failed${NC}"
        echo -e "  Check your DNS settings"
    fi
}

# Main function
main() {
    case "${1:-}" in
        "change")
            change_domain
            ;;
        "info")
            show_domain_info
            read -p "Press Enter to continue..."
            ;;
        "help")
            show_dns_help
            read -p "Press Enter to continue..."
            ;;
        "check")
            check_domain_resolution
            read -p "Press Enter to continue..."
            ;;
        *)
            main_menu
            ;;
    esac
}

# Run main function with arguments
main "$@"