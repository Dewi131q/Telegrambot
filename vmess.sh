#!/bin/bash

# VMess Account Manager
# Created by VPN-Installer

# Source utility functions
source /usr/local/bin/vpn-script/utils.sh

# Check if running as root
check_root

# Configuration files
VMESS_CONFIG_FILE="/etc/vpn-script/config/vmess.json"
VMESS_ACCOUNTS_FILE="/etc/vpn-script/akun/vmess_users.txt"
VMESS_ACCOUNTS_DIR="/etc/vpn-script/akun/vmess"
XRAY_CONFIG="/usr/local/etc/xray/config.json"

# Create directories if not exist
mkdir -p "$(dirname "$VMESS_CONFIG_FILE")"
mkdir -p "$(dirname "$VMESS_ACCOUNTS_FILE")"
mkdir -p "$VMESS_ACCOUNTS_DIR"

# Initialize VMess config if not exists
init_vmess_config() {
    if [[ ! -f "$VMESS_CONFIG_FILE" ]]; then
        cat > "$VMESS_CONFIG_FILE" << 'EOF'
{
    "clients": []
}
EOF
    fi
}

# Update Xray config with VMess clients
update_xray_config() {
    if [[ ! -f "$XRAY_CONFIG" ]]; then
        echo -e "${RED}[ERROR]${NC} Xray config file tidak ditemukan!"
        return 1
    fi
    
    # Get current VMess clients
    local vmess_clients
    if [[ -f "$VMESS_CONFIG_FILE" ]]; then
        vmess_clients=$(jq -c '.clients' "$VMESS_CONFIG_FILE" 2>/dev/null || echo "[]")
    else
        vmess_clients="[]"
    fi
    
    # Update Xray config
    jq --argjson clients "$vmess_clients" '
        .inbounds = (.inbounds | map(
            if .protocol == "vmess" then
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

# Create VMess account
create_vmess_account() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}        CREATE VMESS ACCOUNT${NC}"
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
        if grep -q "^$username:" "$VMESS_ACCOUNTS_FILE" 2>/dev/null; then
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
    
    # Generate UUID and alter ID
    uuid=$(generate_uuid)
    alter_id=0
    
    # Calculate expiry date
    expiry_date=$(get_expiry_date "$days")
    
    # Get domain
    domain=$(get_domain)
    
    # Initialize config
    init_vmess_config
    
    # Add client to VMess config
    jq --arg id "$uuid" --arg email "$username" --argjson alterid $alter_id '
        .clients += [{
            "id": $id,
            "email": $email,
            "alterId": $alterid
        }]
    ' "$VMESS_CONFIG_FILE" > "${VMESS_CONFIG_FILE}.tmp"
    
    mv "${VMESS_CONFIG_FILE}.tmp" "$VMESS_CONFIG_FILE"
    
    # Save account info
    account_info="$username:$uuid:$expiry_date:$max_login:$alter_id"
    echo "$account_info" >> "$VMESS_ACCOUNTS_FILE"
    
    # Create individual account file
    cat > "$VMESS_ACCOUNTS_DIR/$username.txt" << EOF
Username: $username
UUID: $uuid
Created: $(date '+%Y-%m-%d %H:%M:%S')
Expiry: $expiry_date
Max Login: $max_login
Alter ID: $alter_id
Status: Active
Domain: $domain
Port: 8443
Path: /vmess
Protocol: VMess
Network: WebSocket
EOF
    
    # Update Xray configuration
    update_xray_config
    
    # Generate VMess config JSON
    vmess_json=$(cat << EOF
{
    "v": "2",
    "ps": "VMess-$username",
    "add": "$domain",
    "port": "8443",
    "id": "$uuid",
    "aid": "$alter_id",
    "net": "ws",
    "type": "none",
    "host": "$domain",
    "path": "/vmess",
    "tls": "",
    "scy": "auto"
}
EOF
)
    
    # Generate VMess link
    vmess_link="vmess://$(echo "$vmess_json" | base64 -w 0)"
    
    echo ""
    echo -e "${GREEN}[SUCCESS]${NC} Akun VMess berhasil dibuat!"
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}        INFORMASI AKUN VMESS${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "Username      : ${GREEN}$username${NC}"
    echo -e "UUID          : ${GREEN}$uuid${NC}"
    echo -e "Alter ID      : ${GREEN}$alter_id${NC}"
    echo -e "Domain/Host   : ${GREEN}$domain${NC}"
    echo -e "Port          : ${GREEN}8443${NC}"
    echo -e "Path          : ${GREEN}/vmess${NC}"
    echo -e "Network       : ${GREEN}WebSocket${NC}"
    echo -e "Security      : ${GREEN}Auto${NC}"
    echo -e "Masa Aktif    : ${GREEN}$days hari${NC}"
    echo -e "Expired       : ${GREEN}$expiry_date${NC}"
    echo -e "Max Login     : ${GREEN}$max_login${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "${YELLOW}            VMESS LINK${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}$vmess_link${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "${YELLOW}         MANUAL CONFIG${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "Host/Server   : $domain"
    echo -e "Port          : 8443"
    echo -e "UUID          : $uuid"
    echo -e "Alter ID      : $alter_id"
    echo -e "Path          : /vmess"
    echo -e "Network       : WebSocket"
    echo -e "Security      : Auto"
    echo -e "TLS           : None"
    echo -e "${CYAN}========================================${NC}"
    
    # Save link to file
    echo "$vmess_link" > "$VMESS_ACCOUNTS_DIR/$username.link"
    
    # Log activity
    log_activity "VMess account created: $username (expires: $expiry_date)"
}

# List VMess accounts
list_vmess_accounts() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}         VMESS ACCOUNTS LIST${NC}"
    echo -e "${CYAN}========================================${NC}"
    
    if [[ ! -f "$VMESS_ACCOUNTS_FILE" ]] || [[ ! -s "$VMESS_ACCOUNTS_FILE" ]]; then
        echo -e "${YELLOW}[INFO]${NC} Tidak ada akun VMess yang ditemukan."
        return
    fi
    
    echo -e "${YELLOW}Username${NC}     ${YELLOW}Expiry${NC}        ${YELLOW}Max Login${NC}  ${YELLOW}Status${NC}"
    echo -e "-------------------------------------------"
    
    while IFS=':' read -r username uuid expiry max_login alter_id; do
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
    done < "$VMESS_ACCOUNTS_FILE"
    
    echo -e "-------------------------------------------"
    echo -e "Total accounts: ${GREEN}$(get_vmess_count)${NC}"
}

# Delete VMess account
delete_vmess_account() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}        DELETE VMESS ACCOUNT${NC}"
    echo -e "${CYAN}========================================${NC}"
    
    if [[ ! -f "$VMESS_ACCOUNTS_FILE" ]] || [[ ! -s "$VMESS_ACCOUNTS_FILE" ]]; then
        echo -e "${YELLOW}[INFO]${NC} Tidak ada akun VMess yang ditemukan."
        return
    fi
    
    echo ""
    echo -e "${YELLOW}Daftar akun VMess:${NC}"
    list_vmess_accounts
    echo ""
    
    read -p "Username yang akan dihapus: " username
    
    if [[ -z "$username" ]]; then
        echo -e "${RED}[ERROR]${NC} Username tidak boleh kosong!"
        return
    fi
    
    if ! grep -q "^$username:" "$VMESS_ACCOUNTS_FILE"; then
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
    
    # Remove from VMess config
    if [[ -f "$VMESS_CONFIG_FILE" ]]; then
        jq --arg email "$username" '
            .clients = (.clients | map(select(.email != $email)))
        ' "$VMESS_CONFIG_FILE" > "${VMESS_CONFIG_FILE}.tmp"
        
        mv "${VMESS_CONFIG_FILE}.tmp" "$VMESS_CONFIG_FILE"
    fi
    
    # Remove from accounts file
    grep -v "^$username:" "$VMESS_ACCOUNTS_FILE" > "${VMESS_ACCOUNTS_FILE}.tmp"
    mv "${VMESS_ACCOUNTS_FILE}.tmp" "$VMESS_ACCOUNTS_FILE"
    
    # Remove account files
    rm -f "$VMESS_ACCOUNTS_DIR/$username.txt"
    rm -f "$VMESS_ACCOUNTS_DIR/$username.link"
    
    # Update Xray configuration
    update_xray_config
    
    echo -e "${GREEN}[SUCCESS]${NC} User $username berhasil dihapus!"
    
    # Log activity
    log_activity "VMess account deleted: $username"
}

# Renew VMess account
renew_vmess_account() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}        RENEW VMESS ACCOUNT${NC}"
    echo -e "${CYAN}========================================${NC}"
    
    if [[ ! -f "$VMESS_ACCOUNTS_FILE" ]] || [[ ! -s "$VMESS_ACCOUNTS_FILE" ]]; then
        echo -e "${YELLOW}[INFO]${NC} Tidak ada akun VMess yang ditemukan."
        return
    fi
    
    echo ""
    echo -e "${YELLOW}Daftar akun VMess:${NC}"
    list_vmess_accounts
    echo ""
    
    read -p "Username yang akan diperpanjang: " username
    
    if [[ -z "$username" ]]; then
        echo -e "${RED}[ERROR]${NC} Username tidak boleh kosong!"
        return
    fi
    
    if ! grep -q "^$username:" "$VMESS_ACCOUNTS_FILE"; then
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
    while IFS=':' read -r user uuid expiry max_login alter_id; do
        if [[ "$user" == "$username" ]]; then
            echo "$user:$uuid:$new_expiry:$max_login:$alter_id"
        else
            echo "$user:$uuid:$expiry:$max_login:$alter_id"
        fi
    done < "$VMESS_ACCOUNTS_FILE" > "${VMESS_ACCOUNTS_FILE}.tmp"
    
    mv "${VMESS_ACCOUNTS_FILE}.tmp" "$VMESS_ACCOUNTS_FILE"
    
    # Update account file
    if [[ -f "$VMESS_ACCOUNTS_DIR/$username.txt" ]]; then
        sed -i "s/Expiry:.*/Expiry: $new_expiry/" "$VMESS_ACCOUNTS_DIR/$username.txt"
    fi
    
    echo ""
    echo -e "${GREEN}[SUCCESS]${NC} Akun $username berhasil diperpanjang!"
    echo -e "Expired baru: ${GREEN}$new_expiry${NC}"
    
    # Log activity
    log_activity "VMess account renewed: $username (new expiry: $new_expiry)"
}

# Show VMess account details
show_vmess_account() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}       VMESS ACCOUNT DETAILS${NC}"
    echo -e "${CYAN}========================================${NC}"
    
    if [[ ! -f "$VMESS_ACCOUNTS_FILE" ]] || [[ ! -s "$VMESS_ACCOUNTS_FILE" ]]; then
        echo -e "${YELLOW}[INFO]${NC} Tidak ada akun VMess yang ditemukan."
        return
    fi
    
    echo ""
    echo -e "${YELLOW}Daftar akun VMess:${NC}"
    list_vmess_accounts
    echo ""
    
    read -p "Username yang akan ditampilkan: " username
    
    if [[ -z "$username" ]]; then
        echo -e "${RED}[ERROR]${NC} Username tidak boleh kosong!"
        return
    fi
    
    if ! grep -q "^$username:" "$VMESS_ACCOUNTS_FILE"; then
        echo -e "${RED}[ERROR]${NC} User $username tidak ditemukan!"
        return
    fi
    
    # Get account details
    account_line=$(grep "^$username:" "$VMESS_ACCOUNTS_FILE")
    uuid=$(echo "$account_line" | cut -d':' -f2)
    expiry=$(echo "$account_line" | cut -d':' -f3)
    max_login=$(echo "$account_line" | cut -d':' -f4)
    alter_id=$(echo "$account_line" | cut -d':' -f5)
    
    domain=$(get_domain)
    
    # Generate VMess config JSON
    vmess_json=$(cat << EOF
{
    "v": "2",
    "ps": "VMess-$username",
    "add": "$domain",
    "port": "8443",
    "id": "$uuid",
    "aid": "$alter_id",
    "net": "ws",
    "type": "none",
    "host": "$domain",
    "path": "/vmess",
    "tls": "",
    "scy": "auto"
}
EOF
)
    
    vmess_link="vmess://$(echo "$vmess_json" | base64 -w 0)"
    
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}        INFORMASI AKUN VMESS${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "Username      : ${GREEN}$username${NC}"
    echo -e "UUID          : ${GREEN}$uuid${NC}"
    echo -e "Alter ID      : ${GREEN}$alter_id${NC}"
    echo -e "Domain/Host   : ${GREEN}$domain${NC}"
    echo -e "Port          : ${GREEN}8443${NC}"
    echo -e "Path          : ${GREEN}/vmess${NC}"
    echo -e "Network       : ${GREEN}WebSocket${NC}"
    echo -e "Security      : ${GREEN}Auto${NC}"
    echo -e "Expired       : ${GREEN}$expiry${NC}"
    echo -e "Max Login     : ${GREEN}$max_login${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "${YELLOW}            VMESS LINK${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}$vmess_link${NC}"
    echo -e "${CYAN}========================================${NC}"
}

# Clean expired accounts
clean_expired_accounts() {
    if [[ ! -f "$VMESS_ACCOUNTS_FILE" ]]; then
        return
    fi
    
    local expired_count=0
    local temp_file="${VMESS_ACCOUNTS_FILE}.clean"
    
    # Create new file without expired accounts
    > "$temp_file"
    
    while IFS=':' read -r username uuid expiry max_login alter_id; do
        if [[ -n "$username" ]]; then
            if is_expired "$expiry"; then
                # Remove from VMess config
                if [[ -f "$VMESS_CONFIG_FILE" ]]; then
                    jq --arg email "$username" '
                        .clients = (.clients | map(select(.email != $email)))
                    ' "$VMESS_CONFIG_FILE" > "${VMESS_CONFIG_FILE}.tmp"
                    
                    mv "${VMESS_CONFIG_FILE}.tmp" "$VMESS_CONFIG_FILE"
                fi
                
                # Remove account files
                rm -f "$VMESS_ACCOUNTS_DIR/$username.txt"
                rm -f "$VMESS_ACCOUNTS_DIR/$username.link"
                
                # Log expired account
                log_activity "VMess account expired and removed: $username"
                
                ((expired_count++))
            else
                echo "$username:$uuid:$expiry:$max_login:$alter_id" >> "$temp_file"
            fi
        fi
    done < "$VMESS_ACCOUNTS_FILE"
    
    mv "$temp_file" "$VMESS_ACCOUNTS_FILE"
    
    if [[ $expired_count -gt 0 ]]; then
        update_xray_config
        echo -e "${GREEN}[INFO]${NC} $expired_count akun VMess yang expired telah dihapus."
    fi
}

# Main function
main() {
    case "${1:-}" in
        "create")
            create_vmess_account
            ;;
        "list")
            list_vmess_accounts
            ;;
        "delete")
            delete_vmess_account
            ;;
        "renew")
            renew_vmess_account
            ;;
        "show")
            show_vmess_account
            ;;
        "clean")
            clean_expired_accounts
            ;;
        *)
            echo "Usage: $0 {create|list|delete|renew|show|clean}"
            echo ""
            echo "Commands:"
            echo "  create  - Create new VMess account"
            echo "  list    - List all VMess accounts"
            echo "  delete  - Delete VMess account"
            echo "  renew   - Renew VMess account"
            echo "  show    - Show VMess account details"
            echo "  clean   - Clean expired accounts"
            exit 1
            ;;
    esac
}

# Run main function with arguments
main "$@"