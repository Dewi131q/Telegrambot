#!/bin/bash

# VLESS Account Manager
# Created by VPN-Installer

# Source utility functions
source /usr/local/bin/vpn-script/utils.sh

# Check if running as root
check_root

# Configuration files
VLESS_CONFIG_FILE="/etc/vpn-script/config/vless.json"
VLESS_ACCOUNTS_FILE="/etc/vpn-script/akun/vless_users.txt"
VLESS_ACCOUNTS_DIR="/etc/vpn-script/akun/vless"
XRAY_CONFIG="/usr/local/etc/xray/config.json"

# Create directories if not exist
mkdir -p "$(dirname "$VLESS_CONFIG_FILE")"
mkdir -p "$(dirname "$VLESS_ACCOUNTS_FILE")"
mkdir -p "$VLESS_ACCOUNTS_DIR"

# Initialize VLESS config if not exists
init_vless_config() {
    if [[ ! -f "$VLESS_CONFIG_FILE" ]]; then
        cat > "$VLESS_CONFIG_FILE" << 'EOF'
{
    "clients": []
}
EOF
    fi
}

# Update Xray config with VLESS clients
update_xray_config() {
    if [[ ! -f "$XRAY_CONFIG" ]]; then
        echo -e "${RED}[ERROR]${NC} Xray config file tidak ditemukan!"
        return 1
    fi
    
    # Get current VLESS clients
    local vless_clients
    if [[ -f "$VLESS_CONFIG_FILE" ]]; then
        vless_clients=$(jq -c '.clients' "$VLESS_CONFIG_FILE" 2>/dev/null || echo "[]")
    else
        vless_clients="[]"
    fi
    
    # Update Xray config
    jq --argjson clients "$vless_clients" '
        .inbounds = (.inbounds | map(
            if .protocol == "vless" then
                .settings.clients = $clients
            else
                .
            end
        ))
    ' "$XRAY_CONFIG" > "${XRAY_CONFIG}.tmp"
    
    mv "${XRAY_CONFIG}.tmp" "$XRAY_CONFIG"
    
    # Restart Xray service
    systemctl restart xray
}

# Create VLESS account
create_vless_account() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}        CREATE VLESS ACCOUNT${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    
    # Input username
    while true; do
        read -p "Username: " username
        if [[ -z "$username" ]]; then
            echo -e "${RED}[ERROR]${NC} Username tidak boleh kosong!"
            continue
        fi
        
        if [[ "$username" =~ [^a-zA-Z0-9_] ]]; then
            echo -e "${RED}[ERROR]${NC} Username hanya boleh mengandung huruf, angka, dan underscore!"
            continue
        fi
        
        # Check if username already exists
        if grep -q "^$username:" "$VLESS_ACCOUNTS_FILE" 2>/dev/null; then
            echo -e "${RED}[ERROR]${NC} Username $username sudah ada!"
            continue
        fi
        
        break
    done
    
    # Input expiry days
    while true; do
        read -p "Masa aktif (hari): " days
        if [[ ! "$days" =~ ^[0-9]+$ ]] || [[ "$days" -lt 1 ]]; then
            echo -e "${RED}[ERROR]${NC} Masa aktif harus berupa angka positif!"
            continue
        fi
        
        break
    done
    
    # Input connection limit
    while true; do
        read -p "Batas koneksi simultan: " max_login
        if [[ ! "$max_login" =~ ^[0-9]+$ ]] || [[ "$max_login" -lt 1 ]]; then
            echo -e "${RED}[ERROR]${NC} Batas koneksi harus berupa angka positif!"
            continue
        fi
        
        break
    done
    
    # Generate UUID
    uuid=$(generate_uuid)
    
    # Calculate expiry date
    expiry_date=$(get_expiry_date "$days")
    
    # Get domain
    domain=$(get_domain)
    
    # Initialize config
    init_vless_config
    
    # Add client to VLESS config
    jq --arg id "$uuid" --arg email "$username" '
        .clients += [{
            "id": $id,
            "email": $email,
            "flow": ""
        }]
    ' "$VLESS_CONFIG_FILE" > "${VLESS_CONFIG_FILE}.tmp"
    
    mv "${VLESS_CONFIG_FILE}.tmp" "$VLESS_CONFIG_FILE"
    
    # Save account info
    account_info="$username:$uuid:$expiry_date:$max_login"
    echo "$account_info" >> "$VLESS_ACCOUNTS_FILE"
    
    # Create individual account file
    cat > "$VLESS_ACCOUNTS_DIR/$username.txt" << EOF
Username: $username
UUID: $uuid
Created: $(date '+%Y-%m-%d %H:%M:%S')
Expiry: $expiry_date
Max Login: $max_login
Status: Active
Domain: $domain
Port: 8080
Path: /vless
Protocol: VLESS
Network: WebSocket
EOF
    
    # Update Xray configuration
    update_xray_config
    
    # Generate VLESS link
    vless_link="vless://$uuid@$domain:8080?path=/vless&security=none&encryption=none&type=ws&host=$domain#VLESS-$username"
    
    echo ""
    echo -e "${GREEN}[SUCCESS]${NC} Akun VLESS berhasil dibuat!"
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}        INFORMASI AKUN VLESS${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "Username      : ${GREEN}$username${NC}"
    echo -e "UUID          : ${GREEN}$uuid${NC}"
    echo -e "Domain/Host   : ${GREEN}$domain${NC}"
    echo -e "Port          : ${GREEN}8080${NC}"
    echo -e "Path          : ${GREEN}/vless${NC}"
    echo -e "Network       : ${GREEN}WebSocket${NC}"
    echo -e "Security      : ${GREEN}None${NC}"
    echo -e "Masa Aktif    : ${GREEN}$days hari${NC}"
    echo -e "Expired       : ${GREEN}$expiry_date${NC}"
    echo -e "Max Login     : ${GREEN}$max_login${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "${YELLOW}            VLESS LINK${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}$vless_link${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "${YELLOW}         MANUAL CONFIG${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "Host/Server   : $domain"
    echo -e "Port          : 8080"
    echo -e "UUID          : $uuid"
    echo -e "Path          : /vless"
    echo -e "Network       : WebSocket"
    echo -e "Security      : None"
    echo -e "Encryption    : None"
    echo -e "${CYAN}========================================${NC}"
    
    # Save link to file
    echo "$vless_link" > "$VLESS_ACCOUNTS_DIR/$username.link"
    
    # Log activity
    log_activity "VLESS account created: $username (expires: $expiry_date)"
}

# List VLESS accounts
list_vless_accounts() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}         VLESS ACCOUNTS LIST${NC}"
    echo -e "${CYAN}========================================${NC}"
    
    if [[ ! -f "$VLESS_ACCOUNTS_FILE" ]] || [[ ! -s "$VLESS_ACCOUNTS_FILE" ]]; then
        echo -e "${YELLOW}[INFO]${NC} Tidak ada akun VLESS yang ditemukan."
        return
    fi
    
    echo -e "${YELLOW}Username${NC}     ${YELLOW}Expiry${NC}        ${YELLOW}Max Login${NC}  ${YELLOW}Status${NC}"
    echo -e "-------------------------------------------"
    
    while IFS=':' read -r username uuid expiry max_login; do
        if [[ -n "$username" ]]; then
            if is_expired "$expiry"; then
                status="${RED}Expired${NC}"
            else
                days_left=$(days_until_expiry "$expiry")
                if [[ $days_left -le 3 ]]; then
                    status="${YELLOW}$days_left days${NC}"
                else
                    status="${GREEN}Active${NC}"
                fi
            fi
            
            printf "%-12s %-12s %-10s %s\n" "$username" "$expiry" "$max_login" "$status"
        fi
    done < "$VLESS_ACCOUNTS_FILE"
    
    echo -e "-------------------------------------------"
    echo -e "Total accounts: ${GREEN}$(get_vless_count)${NC}"
}

# Delete VLESS account
delete_vless_account() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}        DELETE VLESS ACCOUNT${NC}"
    echo -e "${CYAN}========================================${NC}"
    
    if [[ ! -f "$VLESS_ACCOUNTS_FILE" ]] || [[ ! -s "$VLESS_ACCOUNTS_FILE" ]]; then
        echo -e "${YELLOW}[INFO]${NC} Tidak ada akun VLESS yang ditemukan."
        return
    fi
    
    echo ""
    echo -e "${YELLOW}Daftar akun VLESS:${NC}"
    list_vless_accounts
    echo ""
    
    read -p "Username yang akan dihapus: " username
    
    if [[ -z "$username" ]]; then
        echo -e "${RED}[ERROR]${NC} Username tidak boleh kosong!"
        return
    fi
    
    if ! grep -q "^$username:" "$VLESS_ACCOUNTS_FILE"; then
        echo -e "${RED}[ERROR]${NC} User $username tidak ditemukan!"
        return
    fi
    
    # Confirm deletion
    echo ""
    echo -e "${YELLOW}[WARNING]${NC} Anda yakin ingin menghapus user $username?"
    read -p "Ketik 'yes' untuk konfirmasi: " confirm
    
    if [[ "$confirm" != "yes" ]]; then
        echo -e "${YELLOW}[INFO]${NC} Penghapusan dibatalkan."
        return
    fi
    
    # Get UUID for removal
    uuid=$(grep "^$username:" "$VLESS_ACCOUNTS_FILE" | cut -d':' -f2)
    
    # Remove from VLESS config
    if [[ -f "$VLESS_CONFIG_FILE" ]]; then
        jq --arg email "$username" '
            .clients = (.clients | map(select(.email != $email)))
        ' "$VLESS_CONFIG_FILE" > "${VLESS_CONFIG_FILE}.tmp"
        
        mv "${VLESS_CONFIG_FILE}.tmp" "$VLESS_CONFIG_FILE"
    fi
    
    # Remove from accounts file
    grep -v "^$username:" "$VLESS_ACCOUNTS_FILE" > "${VLESS_ACCOUNTS_FILE}.tmp"
    mv "${VLESS_ACCOUNTS_FILE}.tmp" "$VLESS_ACCOUNTS_FILE"
    
    # Remove account files
    rm -f "$VLESS_ACCOUNTS_DIR/$username.txt"
    rm -f "$VLESS_ACCOUNTS_DIR/$username.link"
    
    # Update Xray configuration
    update_xray_config
    
    echo -e "${GREEN}[SUCCESS]${NC} User $username berhasil dihapus!"
    
    # Log activity
    log_activity "VLESS account deleted: $username"
}

# Renew VLESS account
renew_vless_account() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}        RENEW VLESS ACCOUNT${NC}"
    echo -e "${CYAN}========================================${NC}"
    
    if [[ ! -f "$VLESS_ACCOUNTS_FILE" ]] || [[ ! -s "$VLESS_ACCOUNTS_FILE" ]]; then
        echo -e "${YELLOW}[INFO]${NC} Tidak ada akun VLESS yang ditemukan."
        return
    fi
    
    echo ""
    echo -e "${YELLOW}Daftar akun VLESS:${NC}"
    list_vless_accounts
    echo ""
    
    read -p "Username yang akan diperpanjang: " username
    
    if [[ -z "$username" ]]; then
        echo -e "${RED}[ERROR]${NC} Username tidak boleh kosong!"
        return
    fi
    
    if ! grep -q "^$username:" "$VLESS_ACCOUNTS_FILE"; then
        echo -e "${RED}[ERROR]${NC} User $username tidak ditemukan!"
        return
    fi
    
    # Input new expiry days
    while true; do
        read -p "Perpanjang berapa hari: " days
        if [[ ! "$days" =~ ^[0-9]+$ ]] || [[ "$days" -lt 1 ]]; then
            echo -e "${RED}[ERROR]${NC} Jumlah hari harus berupa angka positif!"
            continue
        fi
        
        break
    done
    
    # Calculate new expiry date
    new_expiry=$(get_expiry_date "$days")
    
    # Update accounts file
    while IFS=':' read -r user uuid expiry max_login; do
        if [[ "$user" == "$username" ]]; then
            echo "$user:$uuid:$new_expiry:$max_login"
        else
            echo "$user:$uuid:$expiry:$max_login"
        fi
    done < "$VLESS_ACCOUNTS_FILE" > "${VLESS_ACCOUNTS_FILE}.tmp"
    
    mv "${VLESS_ACCOUNTS_FILE}.tmp" "$VLESS_ACCOUNTS_FILE"
    
    # Update account file
    if [[ -f "$VLESS_ACCOUNTS_DIR/$username.txt" ]]; then
        sed -i "s/Expiry:.*/Expiry: $new_expiry/" "$VLESS_ACCOUNTS_DIR/$username.txt"
    fi
    
    echo ""
    echo -e "${GREEN}[SUCCESS]${NC} Akun $username berhasil diperpanjang!"
    echo -e "Expired baru: ${GREEN}$new_expiry${NC}"
    
    # Log activity
    log_activity "VLESS account renewed: $username (new expiry: $new_expiry)"
}

# Show VLESS account details
show_vless_account() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}       VLESS ACCOUNT DETAILS${NC}"
    echo -e "${CYAN}========================================${NC}"
    
    if [[ ! -f "$VLESS_ACCOUNTS_FILE" ]] || [[ ! -s "$VLESS_ACCOUNTS_FILE" ]]; then
        echo -e "${YELLOW}[INFO]${NC} Tidak ada akun VLESS yang ditemukan."
        return
    fi
    
    echo ""
    echo -e "${YELLOW}Daftar akun VLESS:${NC}"
    list_vless_accounts
    echo ""
    
    read -p "Username yang akan ditampilkan: " username
    
    if [[ -z "$username" ]]; then
        echo -e "${RED}[ERROR]${NC} Username tidak boleh kosong!"
        return
    fi
    
    if ! grep -q "^$username:" "$VLESS_ACCOUNTS_FILE"; then
        echo -e "${RED}[ERROR]${NC} User $username tidak ditemukan!"
        return
    fi
    
    # Get account details
    account_line=$(grep "^$username:" "$VLESS_ACCOUNTS_FILE")
    uuid=$(echo "$account_line" | cut -d':' -f2)
    expiry=$(echo "$account_line" | cut -d':' -f3)
    max_login=$(echo "$account_line" | cut -d':' -f4)
    
    domain=$(get_domain)
    vless_link="vless://$uuid@$domain:8080?path=/vless&security=none&encryption=none&type=ws&host=$domain#VLESS-$username"
    
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}        INFORMASI AKUN VLESS${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "Username      : ${GREEN}$username${NC}"
    echo -e "UUID          : ${GREEN}$uuid${NC}"
    echo -e "Domain/Host   : ${GREEN}$domain${NC}"
    echo -e "Port          : ${GREEN}8080${NC}"
    echo -e "Path          : ${GREEN}/vless${NC}"
    echo -e "Network       : ${GREEN}WebSocket${NC}"
    echo -e "Security      : ${GREEN}None${NC}"
    echo -e "Expired       : ${GREEN}$expiry${NC}"
    echo -e "Max Login     : ${GREEN}$max_login${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "${YELLOW}            VLESS LINK${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}$vless_link${NC}"
    echo -e "${CYAN}========================================${NC}"
}

# Clean expired accounts
clean_expired_accounts() {
    if [[ ! -f "$VLESS_ACCOUNTS_FILE" ]]; then
        return
    fi
    
    local expired_count=0
    local temp_file="${VLESS_ACCOUNTS_FILE}.clean"
    
    # Create new file without expired accounts
    > "$temp_file"
    
    while IFS=':' read -r username uuid expiry max_login; do
        if [[ -n "$username" ]]; then
            if is_expired "$expiry"; then
                # Remove from VLESS config
                if [[ -f "$VLESS_CONFIG_FILE" ]]; then
                    jq --arg email "$username" '
                        .clients = (.clients | map(select(.email != $email)))
                    ' "$VLESS_CONFIG_FILE" > "${VLESS_CONFIG_FILE}.tmp"
                    
                    mv "${VLESS_CONFIG_FILE}.tmp" "$VLESS_CONFIG_FILE"
                fi
                
                # Remove account files
                rm -f "$VLESS_ACCOUNTS_DIR/$username.txt"
                rm -f "$VLESS_ACCOUNTS_DIR/$username.link"
                
                # Log expired account
                log_activity "VLESS account expired and removed: $username"
                
                ((expired_count++))
            else
                echo "$username:$uuid:$expiry:$max_login" >> "$temp_file"
            fi
        fi
    done < "$VLESS_ACCOUNTS_FILE"
    
    mv "$temp_file" "$VLESS_ACCOUNTS_FILE"
    
    if [[ $expired_count -gt 0 ]]; then
        update_xray_config
        echo -e "${GREEN}[INFO]${NC} $expired_count akun VLESS yang expired telah dihapus."
    fi
}

# Main function
main() {
    case "${1:-}" in
        "create")
            create_vless_account
            ;;
        "list")
            list_vless_accounts
            ;;
        "delete")
            delete_vless_account
            ;;
        "renew")
            renew_vless_account
            ;;
        "show")
            show_vless_account
            ;;
        "clean")
            clean_expired_accounts
            ;;
        *)
            echo "Usage: $0 {create|list|delete|renew|show|clean}"
            echo ""
            echo "Commands:"
            echo "  create  - Create new VLESS account"
            echo "  list    - List all VLESS accounts"
            echo "  delete  - Delete VLESS account"
            echo "  renew   - Renew VLESS account"
            echo "  show    - Show VLESS account details"
            echo "  clean   - Clean expired accounts"
            exit 1
            ;;
    esac
}

# Run main function with arguments
main "$@"