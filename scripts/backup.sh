#!/bin/bash

# ==========================================
# VPN Server Backup and Restore Script
# ==========================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Backup directory
BACKUP_DIR="/backup/vpn"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="vpn_backup_$DATE.tar.gz"

# Source utils
source /usr/local/bin/vpn/utils.sh

# Show banner
show_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    VPN BACKUP & RESTORE                      ║"
    echo "║                        Version 1.0                           ║"
    echo "║                    Author: VPN Script Creator                 ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Create backup
create_backup() {
    clear
    show_banner
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                        CREATE BACKUP                          ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Create backup directory
    mkdir -p "$BACKUP_DIR"
    
    echo -e "${YELLOW}Creating backup...${NC}"
    echo ""
    
    # Create temporary directory for backup
    TEMP_DIR="/tmp/vpn_backup_$DATE"
    mkdir -p "$TEMP_DIR"
    
    # Backup configuration files
    echo -e "${BLUE}Backing up configuration files...${NC}"
    if [[ -d "/etc/xray" ]]; then
        cp -r /etc/xray "$TEMP_DIR/"
    fi
    
    if [[ -f "/etc/issue.net" ]]; then
        cp /etc/issue.net "$TEMP_DIR/"
    fi
    
    # Backup scripts
    echo -e "${BLUE}Backing up VPN scripts...${NC}"
    if [[ -d "/usr/local/bin/vpn" ]]; then
        cp -r /usr/local/bin/vpn "$TEMP_DIR/"
    fi
    
    # Backup account files
    echo -e "${BLUE}Backing up account files...${NC}"
    if [[ -d "/home/vps/public_html/akun" ]]; then
        cp -r /home/vps/public_html/akun "$TEMP_DIR/"
    fi
    
    # Backup web interface
    echo -e "${BLUE}Backing up web interface...${NC}"
    if [[ -d "/home/vps/public_html" ]]; then
        cp -r /home/vps/public_html "$TEMP_DIR/"
    fi
    
    # Backup nginx configuration
    echo -e "${BLUE}Backing up nginx configuration...${NC}"
    if [[ -d "/etc/nginx" ]]; then
        cp -r /etc/nginx "$TEMP_DIR/"
    fi
    
    # Create system information file
    echo -e "${BLUE}Creating system information...${NC}"
    cat > "$TEMP_DIR/system_info.txt" << EOF
VPN Server Backup Information
============================
Backup Date: $(date)
Server IP: $(get_ip)
Domain: $(get_domain)
RAM: $(get_ram)
CPU Cores: $(get_core)
OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)
Kernel: $(uname -r)
EOF
    
    # Create backup archive
    echo -e "${BLUE}Creating backup archive...${NC}"
    cd /tmp
    tar -czf "$BACKUP_DIR/$BACKUP_FILE" "vpn_backup_$DATE"
    
    # Clean up temporary directory
    rm -rf "$TEMP_DIR"
    
    # Check if backup was successful
    if [[ -f "$BACKUP_DIR/$BACKUP_FILE" ]]; then
        BACKUP_SIZE=$(du -h "$BACKUP_DIR/$BACKUP_FILE" | cut -f1)
        echo -e "${GREEN}✓ Backup created successfully!${NC}"
        echo -e "${YELLOW}Backup file: $BACKUP_DIR/$BACKUP_FILE${NC}"
        echo -e "${YELLOW}Backup size: $BACKUP_SIZE${NC}"
    else
        echo -e "${RED}✗ Backup failed!${NC}"
        return 1
    fi
    
    echo ""
    read -p "Press Enter to continue..."
    source /usr/local/bin/vpn/menu.sh
}

# List backups
list_backups() {
    clear
    show_banner
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                        LIST BACKUPS                           ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [[ ! -d "$BACKUP_DIR" ]]; then
        echo -e "${YELLOW}No backup directory found.${NC}"
        echo ""
        read -p "Press Enter to continue..."
        source /usr/local/bin/vpn/menu.sh
        return
    fi
    
    BACKUP_FILES=$(ls -la "$BACKUP_DIR"/*.tar.gz 2>/dev/null | wc -l)
    
    if [[ $BACKUP_FILES -eq 0 ]]; then
        echo -e "${YELLOW}No backup files found.${NC}"
        echo ""
        read -p "Press Enter to continue..."
        source /usr/local/bin/vpn/menu.sh
        return
    fi
    
    echo -e "${YELLOW}Available backups:${NC}"
    echo ""
    
    ls -lah "$BACKUP_DIR"/*.tar.gz | while read -r line; do
        echo -e "${BLUE}$line${NC}"
    done
    
    echo ""
    read -p "Press Enter to continue..."
    source /usr/local/bin/vpn/menu.sh
}

# Restore backup
restore_backup() {
    clear
    show_banner
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                        RESTORE BACKUP                         ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [[ ! -d "$BACKUP_DIR" ]]; then
        echo -e "${YELLOW}No backup directory found.${NC}"
        echo ""
        read -p "Press Enter to continue..."
        source /usr/local/bin/vpn/menu.sh
        return
    fi
    
    BACKUP_FILES=$(ls "$BACKUP_DIR"/*.tar.gz 2>/dev/null)
    
    if [[ -z "$BACKUP_FILES" ]]; then
        echo -e "${YELLOW}No backup files found.${NC}"
        echo ""
        read -p "Press Enter to continue..."
        source /usr/local/bin/vpn/menu.sh
        return
    fi
    
    echo -e "${YELLOW}Available backups:${NC}"
    echo ""
    
    local i=1
    for backup in $BACKUP_FILES; do
        echo -e "${BLUE}[$i] $(basename "$backup")${NC}"
        ((i++))
    done
    
    echo ""
    read -p "Select backup to restore (1-$((i-1))): " choice
    
    if [[ ! "$choice" =~ ^[0-9]+$ ]] || [[ $choice -lt 1 ]] || [[ $choice -gt $((i-1)) ]]; then
        echo -e "${RED}Invalid selection!${NC}"
        echo ""
        read -p "Press Enter to continue..."
        source /usr/local/bin/vpn/menu.sh
        return
    fi
    
    local backup_file=$(echo "$BACKUP_FILES" | sed -n "${choice}p")
    
    echo ""
    echo -e "${YELLOW}Selected backup: $(basename "$backup_file")${NC}"
    echo -e "${RED}Warning: This will overwrite current configuration!${NC}"
    echo ""
    read -p "Are you sure you want to continue? (y/N): " confirm
    
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo -e "${YELLOW}Restore cancelled.${NC}"
        echo ""
        read -p "Press Enter to continue..."
        source /usr/local/bin/vpn/menu.sh
        return
    fi
    
    echo -e "${YELLOW}Restoring backup...${NC}"
    echo ""
    
    # Create temporary directory for extraction
    TEMP_DIR="/tmp/vpn_restore_$DATE"
    mkdir -p "$TEMP_DIR"
    
    # Extract backup
    echo -e "${BLUE}Extracting backup...${NC}"
    tar -xzf "$backup_file" -C /tmp
    
    # Find the extracted directory
    EXTRACTED_DIR=$(find /tmp -name "vpn_backup_*" -type d | head -1)
    
    if [[ -z "$EXTRACTED_DIR" ]]; then
        echo -e "${RED}✗ Failed to extract backup!${NC}"
        rm -rf "$TEMP_DIR"
        echo ""
        read -p "Press Enter to continue..."
        source /usr/local/bin/vpn/menu.sh
        return
    fi
    
    # Restore configuration files
    echo -e "${BLUE}Restoring configuration files...${NC}"
    if [[ -d "$EXTRACTED_DIR/etc/xray" ]]; then
        rm -rf /etc/xray
        cp -r "$EXTRACTED_DIR/etc/xray" /etc/
    fi
    
    if [[ -f "$EXTRACTED_DIR/issue.net" ]]; then
        cp "$EXTRACTED_DIR/issue.net" /etc/
    fi
    
    # Restore scripts
    echo -e "${BLUE}Restoring VPN scripts...${NC}"
    if [[ -d "$EXTRACTED_DIR/usr/local/bin/vpn" ]]; then
        rm -rf /usr/local/bin/vpn
        cp -r "$EXTRACTED_DIR/usr/local/bin/vpn" /usr/local/bin/
        chmod +x /usr/local/bin/vpn/*.sh
    fi
    
    # Restore account files
    echo -e "${BLUE}Restoring account files...${NC}"
    if [[ -d "$EXTRACTED_DIR/home/vps/public_html/akun" ]]; then
        rm -rf /home/vps/public_html/akun
        cp -r "$EXTRACTED_DIR/home/vps/public_html/akun" /home/vps/public_html/
    fi
    
    # Restore web interface
    echo -e "${BLUE}Restoring web interface...${NC}"
    if [[ -d "$EXTRACTED_DIR/home/vps/public_html" ]]; then
        rm -rf /home/vps/public_html
        cp -r "$EXTRACTED_DIR/home/vps/public_html" /home/
        chown -R www-data:www-data /home/vps/public_html
    fi
    
    # Restore nginx configuration
    echo -e "${BLUE}Restoring nginx configuration...${NC}"
    if [[ -d "$EXTRACTED_DIR/etc/nginx" ]]; then
        rm -rf /etc/nginx
        cp -r "$EXTRACTED_DIR/etc/nginx" /etc/
    fi
    
    # Restart services
    echo -e "${BLUE}Restarting services...${NC}"
    systemctl restart nginx
    systemctl restart dropbear
    
    # Clean up
    rm -rf "$EXTRACTED_DIR"
    
    echo -e "${GREEN}✓ Backup restored successfully!${NC}"
    echo ""
    read -p "Press Enter to continue..."
    source /usr/local/bin/vpn/menu.sh
}

# Delete backup
delete_backup() {
    clear
    show_banner
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                        DELETE BACKUP                          ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [[ ! -d "$BACKUP_DIR" ]]; then
        echo -e "${YELLOW}No backup directory found.${NC}"
        echo ""
        read -p "Press Enter to continue..."
        source /usr/local/bin/vpn/menu.sh
        return
    fi
    
    BACKUP_FILES=$(ls "$BACKUP_DIR"/*.tar.gz 2>/dev/null)
    
    if [[ -z "$BACKUP_FILES" ]]; then
        echo -e "${YELLOW}No backup files found.${NC}"
        echo ""
        read -p "Press Enter to continue..."
        source /usr/local/bin/vpn/menu.sh
        return
    fi
    
    echo -e "${YELLOW}Available backups:${NC}"
    echo ""
    
    local i=1
    for backup in $BACKUP_FILES; do
        echo -e "${BLUE}[$i] $(basename "$backup")${NC}"
        ((i++))
    done
    
    echo ""
    read -p "Select backup to delete (1-$((i-1))): " choice
    
    if [[ ! "$choice" =~ ^[0-9]+$ ]] || [[ $choice -lt 1 ]] || [[ $choice -gt $((i-1)) ]]; then
        echo -e "${RED}Invalid selection!${NC}"
        echo ""
        read -p "Press Enter to continue..."
        source /usr/local/bin/vpn/menu.sh
        return
    fi
    
    local backup_file=$(echo "$BACKUP_FILES" | sed -n "${choice}p")
    
    echo ""
    echo -e "${YELLOW}Selected backup: $(basename "$backup_file")${NC}"
    echo -e "${RED}Warning: This action cannot be undone!${NC}"
    echo ""
    read -p "Are you sure you want to delete this backup? (y/N): " confirm
    
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo -e "${YELLOW}Deletion cancelled.${NC}"
        echo ""
        read -p "Press Enter to continue..."
        source /usr/local/bin/vpn/menu.sh
        return
    fi
    
    rm -f "$backup_file"
    echo -e "${GREEN}✓ Backup deleted successfully!${NC}"
    echo ""
    read -p "Press Enter to continue..."
    source /usr/local/bin/vpn/menu.sh
}

# Main menu
main_menu() {
    clear
    show_banner
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    BACKUP & RESTORE MENU                     ║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║  [1] Create Backup                                           ║${NC}"
    echo -e "${CYAN}║  [2] List Backups                                            ║${NC}"
    echo -e "${CYAN}║  [3] Restore Backup                                          ║${NC}"
    echo -e "${CYAN}║  [4] Delete Backup                                           ║${NC}"
    echo -e "${CYAN}║  [5] Back to Main Menu                                       ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    read -p "Select option [1-5]: " choice
    
    case $choice in
        1) create_backup ;;
        2) list_backups ;;
        3) restore_backup ;;
        4) delete_backup ;;
        5) source /usr/local/bin/vpn/menu.sh ;;
        *) echo -e "${RED}Invalid option!${NC}"; sleep 2; main_menu ;;
    esac
}

# Start menu
main_menu