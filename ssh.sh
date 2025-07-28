#!/bin/bash

# SSH Account Manager
# Created by VPN-Installer

# Source utility functions
source /usr/local/bin/vpn-script/utils.sh

# Check if running as root
check_root

# Configuration files
SSH_USERS_FILE="/etc/vpn-script/akun/ssh_users.txt"
SSH_ACCOUNTS_DIR="/etc/vpn-script/akun/ssh"

# Create directories if not exist
mkdir -p "$(dirname "$SSH_USERS_FILE")"
mkdir -p "$SSH_ACCOUNTS_DIR"

# Create SSH account
create_ssh_account() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}         CREATE SSH ACCOUNT${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    
    # Input username
    while true; do
        read -p "Username: " username
        if [[ -z "$username" ]]; then
            echo -e "${RED}[ERROR]${NC} Username tidak boleh kosong!"
            continue
        fi
        
        if user_exists "$username"; then
            echo -e "${RED}[ERROR]${NC} User $username sudah ada!"
            continue
        fi
        
        if [[ "$username" =~ [^a-zA-Z0-9_] ]]; then
            echo -e "${RED}[ERROR]${NC} Username hanya boleh mengandung huruf, angka, dan underscore!"
            continue
        fi
        
        break
    done
    
    # Input password
    while true; do
        read -p "Password: " password
        if [[ -z "$password" ]]; then
            echo -e "${RED}[ERROR]${NC} Password tidak boleh kosong!"
            continue
        fi
        
        if [[ ${#password} -lt 6 ]]; then
            echo -e "${RED}[ERROR]${NC} Password minimal 6 karakter!"
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
    
    # Input quota (optional)
    read -p "Kuota data (GB, kosongkan untuk unlimited): " quota_gb
    if [[ -n "$quota_gb" ]] && [[ ! "$quota_gb" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}[ERROR]${NC} Kuota harus berupa angka!"
        return 1
    fi
    
    # Calculate expiry date
    expiry_date=$(get_expiry_date "$days")
    
    # Create user account
    useradd -M -s /bin/false "$username"
    echo "$username:$password" | chpasswd
    
    # Save account info
    account_info="$username:$password:$expiry_date:$max_login:${quota_gb:-unlimited}"
    echo "$account_info" >> "$SSH_USERS_FILE"
    
    # Create individual account file
    cat > "$SSH_ACCOUNTS_DIR/$username.txt" << EOF
Username: $username
Password: $password
Created: $(date '+%Y-%m-%d %H:%M:%S')
Expiry: $expiry_date
Max Login: $max_login
Quota: ${quota_gb:-unlimited} GB
Status: Active
EOF
    
    # Get domain and ports
    domain=$(get_domain)
    
    echo ""
    echo -e "${GREEN}[SUCCESS]${NC} Akun SSH berhasil dibuat!"
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}         INFORMASI AKUN SSH${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "Username      : ${GREEN}$username${NC}"
    echo -e "Password      : ${GREEN}$password${NC}"
    echo -e "Domain/Host   : ${GREEN}$domain${NC}"
    echo -e "Port SSH      : ${GREEN}22${NC}"
    echo -e "Port Dropbear : ${GREEN}143${NC}"
    echo -e "Masa Aktif    : ${GREEN}$days hari${NC}"
    echo -e "Expired       : ${GREEN}$expiry_date${NC}"
    echo -e "Max Login     : ${GREEN}$max_login${NC}"
    echo -e "Kuota         : ${GREEN}${quota_gb:-unlimited} GB${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "${YELLOW}          PAYLOAD WEBSOCKET${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "GET / HTTP/1.1[crlf]Host: $domain[crlf]Upgrade: websocket[crlf][crlf]"
    echo -e "${CYAN}========================================${NC}"
    echo -e "${YELLOW}            CONFIG STRING${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "$username:$password@$domain:22"
    echo -e "${CYAN}========================================${NC}"
    
    # Log activity
    log_activity "SSH account created: $username (expires: $expiry_date)"
}

# List SSH accounts
list_ssh_accounts() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}          SSH ACCOUNTS LIST${NC}"
    echo -e "${CYAN}========================================${NC}"
    
    if [[ ! -f "$SSH_USERS_FILE" ]] || [[ ! -s "$SSH_USERS_FILE" ]]; then
        echo -e "${YELLOW}[INFO]${NC} Tidak ada akun SSH yang ditemukan."
        return
    fi
    
    echo -e "${YELLOW}Username${NC}     ${YELLOW}Expiry${NC}        ${YELLOW}Max Login${NC}  ${YELLOW}Status${NC}"
    echo -e "-------------------------------------------"
    
    while IFS=':' read -r username password expiry max_login quota; do
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
    done < "$SSH_USERS_FILE"
    
    echo -e "-------------------------------------------"
    echo -e "Total accounts: ${GREEN}$(get_ssh_count)${NC}"
}

# Delete SSH account
delete_ssh_account() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}         DELETE SSH ACCOUNT${NC}"
    echo -e "${CYAN}========================================${NC}"
    
    if [[ ! -f "$SSH_USERS_FILE" ]] || [[ ! -s "$SSH_USERS_FILE" ]]; then
        echo -e "${YELLOW}[INFO]${NC} Tidak ada akun SSH yang ditemukan."
        return
    fi
    
    echo ""
    echo -e "${YELLOW}Daftar akun SSH:${NC}"
    list_ssh_accounts
    echo ""
    
    read -p "Username yang akan dihapus: " username
    
    if [[ -z "$username" ]]; then
        echo -e "${RED}[ERROR]${NC} Username tidak boleh kosong!"
        return
    fi
    
    if ! grep -q "^$username:" "$SSH_USERS_FILE"; then
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
    
    # Delete system user
    if user_exists "$username"; then
        userdel "$username" 2>/dev/null
    fi
    
    # Remove from users file
    grep -v "^$username:" "$SSH_USERS_FILE" > "${SSH_USERS_FILE}.tmp"
    mv "${SSH_USERS_FILE}.tmp" "$SSH_USERS_FILE"
    
    # Remove account file
    rm -f "$SSH_ACCOUNTS_DIR/$username.txt"
    
    echo -e "${GREEN}[SUCCESS]${NC} User $username berhasil dihapus!"
    
    # Log activity
    log_activity "SSH account deleted: $username"
}

# Renew SSH account
renew_ssh_account() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}         RENEW SSH ACCOUNT${NC}"
    echo -e "${CYAN}========================================${NC}"
    
    if [[ ! -f "$SSH_USERS_FILE" ]] || [[ ! -s "$SSH_USERS_FILE" ]]; then
        echo -e "${YELLOW}[INFO]${NC} Tidak ada akun SSH yang ditemukan."
        return
    fi
    
    echo ""
    echo -e "${YELLOW}Daftar akun SSH:${NC}"
    list_ssh_accounts
    echo ""
    
    read -p "Username yang akan diperpanjang: " username
    
    if [[ -z "$username" ]]; then
        echo -e "${RED}[ERROR]${NC} Username tidak boleh kosong!"
        return
    fi
    
    if ! grep -q "^$username:" "$SSH_USERS_FILE"; then
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
    
    # Update users file
    while IFS=':' read -r user password expiry max_login quota; do
        if [[ "$user" == "$username" ]]; then
            echo "$user:$password:$new_expiry:$max_login:$quota"
        else
            echo "$user:$password:$expiry:$max_login:$quota"
        fi
    done < "$SSH_USERS_FILE" > "${SSH_USERS_FILE}.tmp"
    
    mv "${SSH_USERS_FILE}.tmp" "$SSH_USERS_FILE"
    
    # Update account file
    if [[ -f "$SSH_ACCOUNTS_DIR/$username.txt" ]]; then
        sed -i "s/Expiry:.*/Expiry: $new_expiry/" "$SSH_ACCOUNTS_DIR/$username.txt"
    fi
    
    echo ""
    echo -e "${GREEN}[SUCCESS]${NC} Akun $username berhasil diperpanjang!"
    echo -e "Expired baru: ${GREEN}$new_expiry${NC}"
    
    # Log activity
    log_activity "SSH account renewed: $username (new expiry: $new_expiry)"
}

# Check SSH login
check_ssh_login() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}         CHECK SSH LOGIN${NC}"
    echo -e "${CYAN}========================================${NC}"
    
    echo -e "${YELLOW}Online SSH Users:${NC}"
    echo -e "-------------------------------------------"
    
    # Get SSH connections
    ssh_connections=$(who | grep -E "pts|tty" | wc -l)
    
    if [[ $ssh_connections -eq 0 ]]; then
        echo -e "${YELLOW}[INFO]${NC} Tidak ada koneksi SSH aktif."
    else
        echo -e "Username     Terminal   Login Time     From"
        echo -e "-------------------------------------------"
        who | grep -E "pts|tty" | while read line; do
            echo "$line"
        done
        echo -e "-------------------------------------------"
        echo -e "Total connections: ${GREEN}$ssh_connections${NC}"
    fi
    
    echo ""
    echo -e "${YELLOW}Dropbear Connections:${NC}"
    echo -e "-------------------------------------------"
    
    # Check Dropbear connections
    if command -v netstat >/dev/null; then
        dropbear_conn=$(netstat -tnp 2>/dev/null | grep :143 | grep ESTABLISHED | wc -l)
        echo -e "Active Dropbear connections: ${GREEN}$dropbear_conn${NC}"
    else
        echo -e "${YELLOW}[INFO]${NC} netstat tidak tersedia untuk cek koneksi Dropbear."
    fi
}

# Clean expired accounts
clean_expired_accounts() {
    if [[ ! -f "$SSH_USERS_FILE" ]]; then
        return
    fi
    
    local expired_count=0
    
    while IFS=':' read -r username password expiry max_login quota; do
        if [[ -n "$username" ]] && is_expired "$expiry"; then
            # Delete system user
            if user_exists "$username"; then
                userdel "$username" 2>/dev/null
            fi
            
            # Remove account file
            rm -f "$SSH_ACCOUNTS_DIR/$username.txt"
            
            # Log expired account
            log_activity "SSH account expired and removed: $username"
            
            ((expired_count++))
        fi
    done < "$SSH_USERS_FILE"
    
    # Remove expired entries from users file
    if [[ $expired_count -gt 0 ]]; then
        grep -v "$(date '+%Y-%m-%d')" "$SSH_USERS_FILE" > "${SSH_USERS_FILE}.tmp" 2>/dev/null || true
        mv "${SSH_USERS_FILE}.tmp" "$SSH_USERS_FILE" 2>/dev/null || true
        
        echo -e "${GREEN}[INFO]${NC} $expired_count akun SSH yang expired telah dihapus."
    fi
}

# Main function
main() {
    case "${1:-}" in
        "create")
            create_ssh_account
            ;;
        "list")
            list_ssh_accounts
            ;;
        "delete")
            delete_ssh_account
            ;;
        "renew")
            renew_ssh_account
            ;;
        "check")
            check_ssh_login
            ;;
        "clean")
            clean_expired_accounts
            ;;
        *)
            echo "Usage: $0 {create|list|delete|renew|check|clean}"
            echo ""
            echo "Commands:"
            echo "  create  - Create new SSH account"
            echo "  list    - List all SSH accounts"
            echo "  delete  - Delete SSH account"
            echo "  renew   - Renew SSH account"
            echo "  check   - Check SSH login status"
            echo "  clean   - Clean expired accounts"
            exit 1
            ;;
    esac
}

# Run main function with arguments
main "$@"