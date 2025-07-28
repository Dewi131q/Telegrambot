#!/bin/bash

# ==========================================
# VPN Server Uninstall Script
# ==========================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Show banner
show_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    VPN SERVER UNINSTALL                      ║"
    echo "║                        Version 1.0                           ║"
    echo "║                    Author: VPN Script Creator                 ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Error: This script must be run as root!${NC}" 
        exit 1
    fi
}

# Confirm uninstall
confirm_uninstall() {
    clear
    show_banner
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                      UNINSTALL CONFIRMATION                   ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${RED}⚠️  WARNING: This will completely remove the VPN server!${NC}"
    echo ""
    echo -e "${YELLOW}The following will be removed:${NC}"
    echo -e "${BLUE}• VPN scripts and configurations${NC}"
    echo -e "${BLUE}• Account files and web interface${NC}"
    echo -e "${BLUE}• Nginx configuration${NC}"
    echo -e "${BLUE}• System aliases${NC}"
    echo -e "${BLUE}• Backup files (optional)${NC}"
    echo ""
    echo -e "${RED}This action cannot be undone!${NC}"
    echo ""
    read -p "Are you sure you want to continue? (y/N): " confirm
    
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo -e "${YELLOW}Uninstall cancelled.${NC}"
        exit 0
    fi
}

# Stop services
stop_services() {
    echo -e "${YELLOW}Stopping VPN services...${NC}"
    
    # Stop nginx
    if systemctl is-active --quiet nginx; then
        systemctl stop nginx
        echo -e "${GREEN}✓ Nginx stopped${NC}"
    fi
    
    # Stop dropbear
    if systemctl is-active --quiet dropbear; then
        systemctl stop dropbear
        echo -e "${GREEN}✓ Dropbear stopped${NC}"
    fi
    
    # Stop xray if exists
    if systemctl is-active --quiet xray; then
        systemctl stop xray
        echo -e "${GREEN}✓ XRAY stopped${NC}"
    fi
}

# Remove VPN scripts
remove_scripts() {
    echo -e "${YELLOW}Removing VPN scripts...${NC}"
    
    if [[ -d "/usr/local/bin/vpn" ]]; then
        rm -rf /usr/local/bin/vpn
        echo -e "${GREEN}✓ VPN scripts removed${NC}"
    else
        echo -e "${YELLOW}VPN scripts directory not found${NC}"
    fi
}

# Remove configuration files
remove_configs() {
    echo -e "${YELLOW}Removing configuration files...${NC}"
    
    # Remove XRAY config
    if [[ -d "/etc/xray" ]]; then
        rm -rf /etc/xray
        echo -e "${GREEN}✓ XRAY configuration removed${NC}"
    fi
    
    # Remove nginx VPN config
    if [[ -f "/etc/nginx/sites-available/vpn" ]]; then
        rm -f /etc/nginx/sites-available/vpn
        rm -f /etc/nginx/sites-enabled/vpn
        echo -e "${GREEN}✓ Nginx VPN configuration removed${NC}"
    fi
    
    # Restore default nginx config
    if [[ ! -f "/etc/nginx/sites-enabled/default" ]]; then
        ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/
        echo -e "${GREEN}✓ Default nginx configuration restored${NC}"
    fi
}

# Remove web interface
remove_web_interface() {
    echo -e "${YELLOW}Removing web interface...${NC}"
    
    if [[ -d "/home/vps/public_html" ]]; then
        rm -rf /home/vps/public_html
        echo -e "${GREEN}✓ Web interface removed${NC}"
    else
        echo -e "${YELLOW}Web interface directory not found${NC}"
    fi
}

# Remove system aliases
remove_aliases() {
    echo -e "${YELLOW}Removing system aliases...${NC}"
    
    # Remove from bashrc
    if grep -q "alias vpn=" ~/.bashrc; then
        sed -i '/alias vpn=/d' ~/.bashrc
        echo -e "${GREEN}✓ VPN alias removed from bashrc${NC}"
    fi
    
    # Remove from root bashrc
    if [[ -f "/root/.bashrc" ]] && grep -q "alias vpn=" /root/.bashrc; then
        sed -i '/alias vpn=/d' /root/.bashrc
        echo -e "${GREEN}✓ VPN alias removed from root bashrc${NC}"
    fi
}

# Remove backup files
remove_backups() {
    echo -e "${YELLOW}Checking for backup files...${NC}"
    
    if [[ -d "/backup/vpn" ]]; then
        echo -e "${YELLOW}Backup directory found: /backup/vpn${NC}"
        read -p "Do you want to remove backup files? (y/N): " remove_backup
        
        if [[ "$remove_backup" == "y" || "$remove_backup" == "Y" ]]; then
            rm -rf /backup/vpn
            echo -e "${GREEN}✓ Backup files removed${NC}"
        else
            echo -e "${YELLOW}Backup files preserved${NC}"
        fi
    fi
}

# Remove log files
remove_logs() {
    echo -e "${YELLOW}Removing VPN log files...${NC}"
    
    if [[ -d "/var/log/xray" ]]; then
        rm -rf /var/log/xray
        echo -e "${GREEN}✓ XRAY logs removed${NC}"
    fi
}

# Disable services
disable_services() {
    echo -e "${YELLOW}Disabling services...${NC}"
    
    # Disable nginx
    if systemctl is-enabled --quiet nginx; then
        systemctl disable nginx
        echo -e "${GREEN}✓ Nginx disabled${NC}"
    fi
    
    # Disable dropbear
    if systemctl is-enabled --quiet dropbear; then
        systemctl disable dropbear
        echo -e "${GREEN}✓ Dropbear disabled${NC}"
    fi
    
    # Disable xray if exists
    if systemctl is-enabled --quiet xray; then
        systemctl disable xray
        echo -e "${GREEN}✓ XRAY disabled${NC}"
    fi
}

# Remove packages (optional)
remove_packages() {
    echo -e "${YELLOW}Checking for VPN-related packages...${NC}"
    
    read -p "Do you want to remove VPN-related packages? (y/N): " remove_packages
    
    if [[ "$remove_packages" == "y" || "$remove_packages" == "Y" ]]; then
        echo -e "${YELLOW}Removing packages...${NC}"
        
        # Remove nginx
        if dpkg -l | grep -q nginx; then
            apt remove -y nginx nginx-common
            apt autoremove -y
            echo -e "${GREEN}✓ Nginx removed${NC}"
        fi
        
        # Remove dropbear
        if dpkg -l | grep -q dropbear; then
            apt remove -y dropbear
            apt autoremove -y
            echo -e "${GREEN}✓ Dropbear removed${NC}"
        fi
        
        # Remove other VPN-related packages
        local packages=("xray" "v2ray" "shadowsocks-libev")
        for package in "${packages[@]}"; do
            if dpkg -l | grep -q "$package"; then
                apt remove -y "$package"
                echo -e "${GREEN}✓ $package removed${NC}"
            fi
        done
        
        apt autoremove -y
        apt autoclean
    else
        echo -e "${YELLOW}Packages preserved${NC}"
    fi
}

# Clean up temporary files
cleanup_temp() {
    echo -e "${YELLOW}Cleaning up temporary files...${NC}"
    
    # Remove temporary VPN files
    find /tmp -name "*vpn*" -type f -delete 2>/dev/null
    find /tmp -name "*vpn*" -type d -exec rm -rf {} + 2>/dev/null
    
    echo -e "${GREEN}✓ Temporary files cleaned${NC}"
}

# Show uninstall summary
show_summary() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}                    UNINSTALL COMPLETE                          ${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${GREEN}✓ VPN server has been completely removed${NC}"
    echo ""
    echo -e "${YELLOW}What was removed:${NC}"
    echo -e "${BLUE}• VPN scripts and configurations${NC}"
    echo -e "${BLUE}• Account files and web interface${NC}"
    echo -e "${BLUE}• Nginx VPN configuration${NC}"
    echo -e "${BLUE}• System aliases${NC}"
    echo -e "${BLUE}• VPN log files${NC}"
    echo ""
    echo -e "${YELLOW}Note:${NC}"
    echo -e "${BLUE}• System packages may still be installed${NC}"
    echo -e "${BLUE}• Backup files may still exist${NC}"
    echo -e "${BLUE}• You may need to restart the system${NC}"
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
}

# Main uninstall function
main_uninstall() {
    check_root
    confirm_uninstall
    
    echo -e "${YELLOW}Starting VPN server uninstall...${NC}"
    echo ""
    
    # Stop services first
    stop_services
    
    # Remove components
    remove_scripts
    remove_configs
    remove_web_interface
    remove_aliases
    remove_backups
    remove_logs
    
    # Disable services
    disable_services
    
    # Optional package removal
    remove_packages
    
    # Cleanup
    cleanup_temp
    
    # Show summary
    show_summary
    
    echo ""
    read -p "Press Enter to exit..."
}

# Run uninstall if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_uninstall
fi