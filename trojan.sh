#!/bin/bash

# Trojan Account Manager
# Created by VPN-Installer

# Source utility functions
source /usr/local/bin/vpn-script/utils.sh

# Check if running as root
check_root

# Configuration files
TROJAN_CONFIG_FILE="/etc/vpn-script/config/trojan.json"
TROJAN_ACCOUNTS_FILE="/etc/vpn-script/akun/trojan_users.txt"
TROJAN_ACCOUNTS_DIR="/etc/vpn-script/akun/trojan"
XRAY_CONFIG="/usr/local/etc/xray/config.json"

# Create directories if not exist
mkdir -p "$(dirname "$TROJAN_CONFIG_FILE")"
mkdir -p "$(dirname "$TROJAN_ACCOUNTS_FILE")"
mkdir -p "$TROJAN_ACCOUNTS_DIR"

# Initialize Trojan config if not exists
init_trojan_config() {
    if [[ ! -f "$TROJAN_CONFIG_FILE" ]]; then
        cat > "$TROJAN_CONFIG_FILE" << 'EOF'
{
    "clients": []
}
EOF
    fi
}

# Update Xray config with Trojan clients
update_xray_config() {
    if [[ ! -f "$XRAY_CONFIG" ]]; then
        echo -e "${RED}[ERROR]${NC} Xray config file tidak ditemukan!"
        return 1
    fi
    
    # Get current Trojan clients
    local trojan_clients
    if [[ -f "$TROJAN_CONFIG_FILE" ]]; then
        trojan_clients=$(jq -c '.clients' "$TROJAN_CONFIG_FILE" 2>/dev/null || echo "[]")
    else
        trojan_clients="[]"
    fi
    
    # Update Xray config
    jq --argjson clients "$trojan_clients" '
        .inbounds = (.inbounds | map(
            if .protocol == "trojan" then
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

# Create Trojan account
create_trojan_account() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}       CREATE TROJAN ACCOUNT${NC}"
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
        if grep -q "^$username:" "$TROJAN_ACCOUNTS_FILE" 2>/dev/null; then
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
    
    # Generate password
    password=$(generate_random_string 32)
    
    # Calculate expiry date
    expiry_date=$(get_expiry_date "$days")
    
    # Get domain
    domain=$(get_domain)
    
    # Initialize config
    init_trojan_config
    
    # Add client to Trojan config
    jq --arg password "$password" --arg email "$username" '
        .clients += [{
            "password": $password,
            "email": $email
        }]
    ' "$TROJAN_CONFIG_FILE" > "${TROJAN_CONFIG_FILE}.tmp"
    
    mv "${TROJAN_CONFIG_FILE}.tmp" "$TROJAN_CONFIG_FILE"
    
    # Save account info
    account_info="$username:$password:$expiry_date:$max_login"
    echo "$account_info" >> "$TROJAN_ACCOUNTS_FILE"
    
    # Create individual account file
    cat > "$TROJAN_ACCOUNTS_DIR/$username.txt" << EOF
Username: $username
Password: $password
Created: $(date '+%Y-%m-%d %H:%M:%S')
Expiry: $expiry_date
Max Login: $max_login
Status: Active
Domain: $domain
Port: 2096
Path: /trojan
Protocol: Trojan
Network: WebSocket
EOF
    
    # Update Xray configuration
    update_xray_config
    
    # Generate Trojan link
    trojan_link="trojan://$password@$domain:2096?path=/trojan&security=none&type=ws&host=$domain#Trojan-$username"
    
    echo ""
    echo -e "${GREEN}[SUCCESS]${NC} Akun Trojan berhasil dibuat!"
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}       INFORMASI AKUN TROJAN${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "Username      : ${GREEN}$username${NC}"
    echo -e "Password      : ${GREEN}$password${NC}"
    echo -e "Domain/Host   : ${GREEN}$domain${NC}"
    echo -e "Port          : ${GREEN}2096${NC}"
    echo -e "Path          : ${GREEN}/trojan${NC}"
    echo -e "Network       : ${GREEN}WebSocket${NC}"
    echo -e "Security      : ${GREEN}None${NC}"
    echo -e "Masa Aktif    : ${GREEN}$days hari${NC}"
    echo -e "Expired       : ${GREEN}$expiry_date${NC}"
    echo -e "Max Login     : ${GREEN}$max_login${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "${YELLOW}           TROJAN LINK${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}$trojan_link${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "${YELLOW}         MANUAL CONFIG${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "Host/Server   : $domain"
    echo -e "Port          : 2096"
    echo -e "Password      : $password"
    echo -e "Path          : /trojan"
    echo -e "Network       : WebSocket"
    echo -e "Security      : None"
    echo -e "TLS           : None"
    echo -e "${CYAN}========================================${NC}"
    
    # Save link to file
    echo "$trojan_link" > "$TROJAN_ACCOUNTS_DIR/$username.link"
    
    # Log activity
    log_activity "Trojan account created: $username (expires: $expiry_date)"
}

# List Trojan accounts
list_trojan_accounts() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}        TROJAN ACCOUNTS LIST${NC}"
    echo -e "${CYAN}========================================${NC}"
    
    if [[ ! -f "$TROJAN_ACCOUNTS_FILE" ]] || [[ ! -s "$TROJAN_ACCOUNTS_FILE" ]]; then
        echo -e "${YELLOW}[INFO]${NC} Tidak ada akun Trojan yang ditemukan."
        return
    fi
    
    echo -e "${YELLOW}Username${NC}     ${YELLOW}Expiry${NC}        ${YELLOW}Max Login${NC}  ${YELLOW}Status${NC}"
    echo -e "-------------------------------------------"
    
    while IFS=':' read -r username password expiry max_login; do
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
    done < "$TROJAN_ACCOUNTS_FILE"
    
    echo -e "-------------------------------------------"
    echo -e "Total accounts: ${GREEN}$(get_trojan_count)${NC}"
}

# Delete Trojan account
delete_trojan_account() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}       DELETE TROJAN ACCOUNT${NC}"
    echo -e "${CYAN}========================================${NC}"
    
    if [[ ! -f "$TROJAN_ACCOUNTS_FILE" ]] || [[ ! -s "$TROJAN_ACCOUNTS_FILE" ]]; then
        echo -e "${YELLOW}[INFO]${NC} Tidak ada akun Trojan yang ditemukan."
        return
    fi
    
    echo ""
    echo -e "${YELLOW}Daftar akun Trojan:${NC}"
    list_trojan_accounts
    echo ""
    
    read -p "Username yang akan dihapus: " username
    
    if [[ -z "$username" ]]; then
        echo -e "${RED}[ERROR]${NC} Username tidak boleh kosong!"
        return
    fi
    
    if ! grep -q "^$username:" "$TROJAN_ACCOUNTS_FILE"; then
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
    
    # Remove from Trojan config
    if [[ -f "$TROJAN_CONFIG_FILE" ]]; then
        jq --arg email "$username" '
            .clients = (.clients | map(select(.email != $email)))
        ' "$TROJAN_CONFIG_FILE" > "${TROJAN_CONFIG_FILE}.tmp"
        
        mv "${TROJAN_CONFIG_FILE}.tmp" "$TROJAN_CONFIG_FILE"
    fi
    
    # Remove from accounts file
    grep -v "^$username:" "$TROJAN_ACCOUNTS_FILE" > "${TROJAN_ACCOUNTS_FILE}.tmp"
    mv "${TROJAN_ACCOUNTS_FILE}.tmp" "$TROJAN_ACCOUNTS_FILE"
    
    # Remove account files
    rm -f "$TROJAN_ACCOUNTS_DIR/$username.txt"
    rm -f "$TROJAN_ACCOUNTS_DIR/$username.link"
    
    # Update Xray configuration
    update_xray_config
    
    echo -e "${GREEN}[SUCCESS]${NC} User $username berhasil dihapus!"
    
    # Log activity
    log_activity "Trojan account deleted: $username"
}

# Renew Trojan account
renew_trojan_account() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}       RENEW TROJAN ACCOUNT${NC}"
    echo -e "${CYAN}========================================${NC}"
    
    if [[ ! -f "$TROJAN_ACCOUNTS_FILE" ]] || [[ ! -s "$TROJAN_ACCOUNTS_FILE" ]]; then
        echo -e "${YELLOW}[INFO]${NC} Tidak ada akun Trojan yang ditemukan."
        return
    fi
    
    echo ""
    echo -e "${YELLOW}Daftar akun Trojan:${NC}"
    list_trojan_accounts
    echo ""
    
    read -p "Username yang akan diperpanjang: " username
    
    if [[ -z "$username" ]]; then
        echo -e "${RED}[ERROR]${NC} Username tidak boleh kosong!"
        return
    fi
    
    if ! grep -q "^$username:" "$TROJAN_ACCOUNTS_FILE"; then
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
    while IFS=':' read -r user password expiry max_login; do
        if [[ "$user" == "$username" ]]; then
            echo "$user:$password:$new_expiry:$max_login"
        else
            echo "$user:$password:$expiry:$max_login"
        fi
    done < "$TROJAN_ACCOUNTS_FILE" > "${TROJAN_ACCOUNTS_FILE}.tmp"
    
    mv "${TROJAN_ACCOUNTS_FILE}.tmp" "$TROJAN_ACCOUNTS_FILE"
    
    # Update account file
    if [[ -f "$TROJAN_ACCOUNTS_DIR/$username.txt" ]]; then
        sed -i "s/Expiry:.*/Expiry: $new_expiry/" "$TROJAN_ACCOUNTS_DIR/$username.txt"
    fi
    
    echo ""
    echo -e "${GREEN}[SUCCESS]${NC} Akun $username berhasil diperpanjang!"
    echo -e "Expired baru: ${GREEN}$new_expiry${NC}"
    
    # Log activity
    log_activity "Trojan account renewed: $username (new expiry: $new_expiry)"
}

# Show Trojan account details
show_trojan_account() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}      TROJAN ACCOUNT DETAILS${NC}"
    echo -e "${CYAN}========================================${NC}"
    
    if [[ ! -f "$TROJAN_ACCOUNTS_FILE" ]] || [[ ! -s "$TROJAN_ACCOUNTS_FILE" ]]; then
        echo -e "${YELLOW}[INFO]${NC} Tidak ada akun Trojan yang ditemukan."
        return
    fi
    
    echo ""
    echo -e "${YELLOW}Daftar akun Trojan:${NC}"
    list_trojan_accounts
    echo ""
    
    read -p "Username yang akan ditampilkan: " username
    
    if [[ -z "$username" ]]; then
        echo -e "${RED}[ERROR]${NC} Username tidak boleh kosong!"
        return
    fi
    
    if ! grep -q "^$username:" "$TROJAN_ACCOUNTS_FILE"; then
        echo -e "${RED}[ERROR]${NC} User $username tidak ditemukan!"
        return
    fi
    
    # Get account details
    account_line=$(grep "^$username:" "$TROJAN_ACCOUNTS_FILE")
    password=$(echo "$account_line" | cut -d':' -f2)
    expiry=$(echo "$account_line" | cut -d':' -f3)
    max_login=$(echo "$account_line" | cut -d':' -f4)
    
    domain=$(get_domain)
    trojan_link="trojan://$password@$domain:2096?path=/trojan&security=none&type=ws&host=$domain#Trojan-$username"
    
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}       INFORMASI AKUN TROJAN${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "Username      : ${GREEN}$username${NC}"
    echo -e "Password      : ${GREEN}$password${NC}"
    echo -e "Domain/Host   : ${GREEN}$domain${NC}"
    echo -e "Port          : ${GREEN}2096${NC}"
    echo -e "Path          : ${GREEN}/trojan${NC}"
    echo -e "Network       : ${GREEN}WebSocket${NC}"
    echo -e "Security      : ${GREEN}None${NC}"
    echo -e "Expired       : ${GREEN}$expiry${NC}"
    echo -e "Max Login     : ${GREEN}$max_login${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "${YELLOW}           TROJAN LINK${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}$trojan_link${NC}"
    echo -e "${CYAN}========================================${NC}"
}

# Clean expired accounts
clean_expired_accounts() {
    if [[ ! -f "$TROJAN_ACCOUNTS_FILE" ]]; then
        return
    fi
    
    local expired_count=0
    local temp_file="${TROJAN_ACCOUNTS_FILE}.clean"
    
    # Create new file without expired accounts
    > "$temp_file"
    
    while IFS=':' read -r username password expiry max_login; do
        if [[ -n "$username" ]]; then
            if is_expired "$expiry"; then
                # Remove from Trojan config
                if [[ -f "$TROJAN_CONFIG_FILE" ]]; then
                    jq --arg email "$username" '
                        .clients = (.clients | map(select(.email != $email)))
                    ' "$TROJAN_CONFIG_FILE" > "${TROJAN_CONFIG_FILE}.tmp"
                    
                    mv "${TROJAN_CONFIG_FILE}.tmp" "$TROJAN_CONFIG_FILE"
                fi
                
                # Remove account files
                rm -f "$TROJAN_ACCOUNTS_DIR/$username.txt"
                rm -f "$TROJAN_ACCOUNTS_DIR/$username.link"
                
                # Log expired account
                log_activity "Trojan account expired and removed: $username"
                
                ((expired_count++))
            else
                echo "$username:$password:$expiry:$max_login" >> "$temp_file"
            fi
        fi
    done < "$TROJAN_ACCOUNTS_FILE"
    
    mv "$temp_file" "$TROJAN_ACCOUNTS_FILE"
    
    if [[ $expired_count -gt 0 ]]; then
        update_xray_config
        echo -e "${GREEN}[INFO]${NC} $expired_count akun Trojan yang expired telah dihapus."
    fi
}

# Main function
main() {
    case "${1:-}" in
        "create")
            create_trojan_account
            ;;
        "list")
            list_trojan_accounts
            ;;
        "delete")
            delete_trojan_account
            ;;
        "renew")
            renew_trojan_account
            ;;
        "show")
            show_trojan_account
            ;;
        "clean")
            clean_expired_accounts
            ;;
        *)
            echo "Usage: $0 {create|list|delete|renew|show|clean}"
            echo ""
            echo "Commands:"
            echo "  create  - Create new Trojan account"
            echo "  list    - List all Trojan accounts"
            echo "  delete  - Delete Trojan account"
            echo "  renew   - Renew Trojan account"
            echo "  show    - Show Trojan account details"
            echo "  clean   - Clean expired accounts"
            exit 1
            ;;
    esac
}

# Run main function with arguments
main "$@"