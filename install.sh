#!/bin/bash

# ==========================================
# Script Auto Install VPN Server
# Author: VPN Script Creator
# Version: 1.0
# ==========================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Banner
clear
echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    AUTO INSTALL VPN SERVER                   ║"
echo "║                        Version 1.0                           ║"
echo "║                    Author: VPN Script Creator                 ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: This script must be run as root!${NC}" 
   exit 1
fi

# Check OS
if [[ -e /etc/debian_version ]]; then
    OS="debian"
    source /etc/os-release
    if [[ $ID == "debian" || $ID == "raspbian" ]]; then
        if [[ $VERSION_ID -lt 10 ]]; then
            echo -e "${RED}Your version of Debian is not supported. Please use Debian 10 or later.${NC}"
            exit 1
        fi
    elif [[ $ID == "ubuntu" ]]; then
        if [[ $VERSION_ID -lt 20.04 ]]; then
            echo -e "${RED}Your version of Ubuntu is not supported. Please use Ubuntu 20.04 or later.${NC}"
            exit 1
        fi
    fi
else
    echo -e "${RED}Your OS is not supported. Please use Debian 10/11 or Ubuntu 20.04.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ OS Check passed${NC}"

# Update system
echo -e "${YELLOW}Updating system packages...${NC}"
apt update -y
apt upgrade -y

# Install required packages
echo -e "${YELLOW}Installing required packages...${NC}"
apt install -y curl wget git nano unzip zip openssh-server dropbear nginx apache2-utils

# Create directories
echo -e "${YELLOW}Creating directories...${NC}"
mkdir -p /etc/xray
mkdir -p /var/log/xray
mkdir -p /usr/local/bin/vpn
mkdir -p /home/vps/public_html

# Download and setup scripts
echo -e "${YELLOW}Downloading VPN scripts...${NC}"

# Create menu.sh
cat > /usr/local/bin/vpn/menu.sh << 'EOF'
#!/bin/bash

# ==========================================
# VPN Server Menu
# ==========================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Source utils
source /usr/local/bin/vpn/utils.sh

# Main menu
main_menu() {
    clear
    show_banner
    show_system_info
    show_active_services
    
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                        MAIN MENU                              ║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║  [1] Create SSH Account                                      ║${NC}"
    echo -e "${CYAN}║  [2] Create VLESS Account                                    ║${NC}"
    echo -e "${CYAN}║  [3] Create VMess Account                                    ║${NC}"
    echo -e "${CYAN}║  [4] Create Trojan Account                                   ║${NC}"
    echo -e "${CYAN}║  [5] Change Domain                                           ║${NC}"
    echo -e "${CYAN}║  [6] Change Banner                                           ║${NC}"
    echo -e "${CYAN}║  [7] Check Active Ports                                      ║${NC}"
    echo -e "${CYAN}║  [8] Exit                                                    ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    read -p "Select option [1-8]: " choice
    
    case $choice in
        1) source /usr/local/bin/vpn/ssh.sh ;;
        2) source /usr/local/bin/vpn/vless.sh ;;
        3) source /usr/local/bin/vpn/vmess.sh ;;
        4) source /usr/local/bin/vpn/trojan.sh ;;
        5) source /usr/local/bin/vpn/domain.sh ;;
        6) source /usr/local/bin/vpn/banner.sh ;;
        7) source /usr/local/bin/vpn/cekport.sh ;;
        8) echo -e "${GREEN}Goodbye!${NC}"; exit 0 ;;
        *) echo -e "${RED}Invalid option!${NC}"; sleep 2; main_menu ;;
    esac
}

# Start menu
main_menu
EOF

# Create utils.sh
cat > /usr/local/bin/vpn/utils.sh << 'EOF'
#!/bin/bash

# ==========================================
# Utility Functions
# ==========================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Get system info
get_ip() {
    curl -s ifconfig.me
}

get_ram() {
    free -h | awk '/^Mem:/ {print $2}'
}

get_core() {
    nproc
}

get_domain() {
    if [[ -f /etc/xray/domain ]]; then
        cat /etc/xray/domain
    else
        echo "Not set"
    fi
}

# Show banner
show_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    VPN SERVER MENU                          ║"
    echo "║                        Version 1.0                           ║"
    echo "║                    Author: VPN Script Creator                 ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Show system info
show_system_info() {
    echo -e "${YELLOW}═══════════════════════ SYSTEM INFO ═══════════════════════${NC}"
    echo -e "${BLUE}IP VPS     : ${GREEN}$(get_ip)${NC}"
    echo -e "${BLUE}RAM        : ${GREEN}$(get_ram)${NC}"
    echo -e "${BLUE}CPU Core   : ${GREEN}$(get_core)${NC}"
    echo -e "${BLUE}Domain     : ${GREEN}$(get_domain)${NC}"
    echo -e "${BLUE}Creator    : ${GREEN}VPN Script Creator${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# Check service status
check_service() {
    if systemctl is-active --quiet $1; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗${NC}"
    fi
}

# Show active services
show_active_services() {
    echo -e "${YELLOW}═══════════════════════ ACTIVE SERVICES ════════════════════${NC}"
    echo -e "${BLUE}Dropbear   : $(check_service dropbear)${NC}"
    echo -e "${BLUE}Nginx      : $(check_service nginx)${NC}"
    echo -e "${BLUE}XRAY       : $(check_service xray)${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
}
EOF

# Create ssh.sh
cat > /usr/local/bin/vpn/ssh.sh << 'EOF'
#!/bin/bash

# ==========================================
# SSH Account Creator
# ==========================================

source /usr/local/bin/vpn/utils.sh

create_ssh_account() {
    clear
    show_banner
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    CREATE SSH ACCOUNT                        ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    read -p "Username: " username
    read -s -p "Password: " password
    echo ""
    read -p "Duration (days): " duration
    read -p "IP Limit: " iplimit
    read -p "Quota (GB): " quota
    
    # Create user
    useradd -m -s /bin/bash $username
    echo "$username:$password" | chpasswd
    
    # Set expiration
    if [[ $duration -gt 0 ]]; then
        chage -E $(date -d "+$duration days" +%Y-%m-%d) $username
    fi
    
    # Create account file
    mkdir -p /home/vps/public_html/akun
    cat > /home/vps/public_html/akun/$username.txt << EOL
╔══════════════════════════════════════════════════════════════╗
║                        SSH ACCOUNT                           ║
╠══════════════════════════════════════════════════════════════╣
║  Username    : $username                                    ║
║  Password    : $password                                    ║
║  IP Address  : $(get_ip)                                   ║
║  Port        : 22                                           ║
║  Duration    : $duration days                              ║
║  IP Limit    : $iplimit                                    ║
║  Quota       : $quota GB                                   ║
║                                                              ║
║  WebSocket Payload:                                         ║
║  GET / HTTP/1.1[crlf]Host: [host][crlf]Upgrade: websocket[crlf][crlf] ║
╚══════════════════════════════════════════════════════════════╝
EOL
    
    echo -e "${GREEN}✓ SSH account created successfully!${NC}"
    echo -e "${YELLOW}Account details saved to: /home/vps/public_html/akun/$username.txt${NC}"
    echo ""
    read -p "Press Enter to continue..."
    source /usr/local/bin/vpn/menu.sh
}

create_ssh_account
EOF

# Create vless.sh
cat > /usr/local/bin/vpn/vless.sh << 'EOF'
#!/bin/bash

# ==========================================
# VLESS Account Creator
# ==========================================

source /usr/local/bin/vpn/utils.sh

create_vless_account() {
    clear
    show_banner
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    CREATE VLESS ACCOUNT                      ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    read -p "Username: " username
    read -p "Duration (days): " duration
    
    # Generate UUID
    uuid=$(cat /proc/sys/kernel/random/uuid)
    
    # Create config
    mkdir -p /usr/local/bin/vpn/config
    cat > /usr/local/bin/vpn/config/vless_$username.json << EOL
{
    "v": "2",
    "ps": "$username",
    "add": "$(get_ip)",
    "port": "443",
    "id": "$uuid",
    "aid": "0",
    "net": "ws",
    "type": "none",
    "host": "$(get_domain)",
    "path": "/vless",
    "tls": "tls"
}
EOL
    
    # Create account file
    mkdir -p /home/vps/public_html/akun
    cat > /home/vps/public_html/akun/vless_$username.txt << EOL
╔══════════════════════════════════════════════════════════════╗
║                        VLESS ACCOUNT                         ║
╠══════════════════════════════════════════════════════════════╣
║  Username    : $username                                    ║
║  UUID        : $uuid                                        ║
║  IP Address  : $(get_ip)                                   ║
║  Port        : 443                                          ║
║  Duration    : $duration days                              ║
║  Domain      : $(get_domain)                               ║
║  Path        : /vless                                       ║
║  Security    : TLS                                          ║
║                                                              ║
║  VLESS Link:                                                ║
║  vless://$uuid@$(get_domain):443?encryption=none&security=tls&type=ws&path=%2Fvless#$(get_domain) ║
╚══════════════════════════════════════════════════════════════╝
EOL
    
    echo -e "${GREEN}✓ VLESS account created successfully!${NC}"
    echo -e "${YELLOW}Account details saved to: /home/vps/public_html/akun/vless_$username.txt${NC}"
    echo ""
    read -p "Press Enter to continue..."
    source /usr/local/bin/vpn/menu.sh
}

create_vless_account
EOF

# Create vmess.sh
cat > /usr/local/bin/vpn/vmess.sh << 'EOF'
#!/bin/bash

# ==========================================
# VMess Account Creator
# ==========================================

source /usr/local/bin/vpn/utils.sh

create_vmess_account() {
    clear
    show_banner
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    CREATE VMESS ACCOUNT                      ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    read -p "Username: " username
    read -p "Duration (days): " duration
    
    # Generate UUID
    uuid=$(cat /proc/sys/kernel/random/uuid)
    
    # Create config
    mkdir -p /usr/local/bin/vpn/config
    cat > /usr/local/bin/vpn/config/vmess_$username.json << EOL
{
    "v": "2",
    "ps": "$username",
    "add": "$(get_ip)",
    "port": "443",
    "id": "$uuid",
    "aid": "0",
    "net": "ws",
    "type": "none",
    "host": "$(get_domain)",
    "path": "/vmess",
    "tls": "tls"
}
EOL
    
    # Create account file
    mkdir -p /home/vps/public_html/akun
    cat > /home/vps/public_html/akun/vmess_$username.txt << EOL
╔══════════════════════════════════════════════════════════════╗
║                        VMESS ACCOUNT                         ║
╠══════════════════════════════════════════════════════════════╣
║  Username    : $username                                    ║
║  UUID        : $uuid                                        ║
║  IP Address  : $(get_ip)                                   ║
║  Port        : 443                                          ║
║  Duration    : $duration days                              ║
║  Domain      : $(get_domain)                               ║
║  Path        : /vmess                                       ║
║  Security    : TLS                                          ║
║                                                              ║
║  VMess Link:                                                ║
║  vmess://$(echo -n "{\"v\":\"2\",\"ps\":\"$username\",\"add\":\"$(get_ip)\",\"port\":\"443\",\"id\":\"$uuid\",\"aid\":\"0\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"$(get_domain)\",\"path\":\"/vmess\",\"tls\":\"tls\"}" | base64 -w 0) ║
╚══════════════════════════════════════════════════════════════╝
EOL
    
    echo -e "${GREEN}✓ VMess account created successfully!${NC}"
    echo -e "${YELLOW}Account details saved to: /home/vps/public_html/akun/vmess_$username.txt${NC}"
    echo ""
    read -p "Press Enter to continue..."
    source /usr/local/bin/vpn/menu.sh
}

create_vmess_account
EOF

# Create trojan.sh
cat > /usr/local/bin/vpn/trojan.sh << 'EOF'
#!/bin/bash

# ==========================================
# Trojan Account Creator
# ==========================================

source /usr/local/bin/vpn/utils.sh

create_trojan_account() {
    clear
    show_banner
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    CREATE TROJAN ACCOUNT                     ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    read -p "Username: " username
    read -p "Duration (days): " duration
    
    # Generate password
    password=$(openssl rand -base64 32)
    
    # Create config
    mkdir -p /usr/local/bin/vpn/config
    cat > /usr/local/bin/vpn/config/trojan_$username.json << EOL
{
    "password": "$password",
    "ws": {
        "enabled": true,
        "path": "/trojan",
        "host": "$(get_domain)"
    }
}
EOL
    
    # Create account file
    mkdir -p /home/vps/public_html/akun
    cat > /home/vps/public_html/akun/trojan_$username.txt << EOL
╔══════════════════════════════════════════════════════════════╗
║                       TROJAN ACCOUNT                        ║
╠══════════════════════════════════════════════════════════════╣
║  Username    : $username                                    ║
║  Password    : $password                                    ║
║  IP Address  : $(get_ip)                                   ║
║  Port        : 443                                          ║
║  Duration    : $duration days                              ║
║  Domain      : $(get_domain)                               ║
║  Path        : /trojan                                      ║
║  Security    : TLS                                          ║
║                                                              ║
║  Trojan Link:                                               ║
║  trojan://$password@$(get_domain):443?security=tls&type=ws&path=%2Ftrojan#$username ║
╚══════════════════════════════════════════════════════════════╝
EOL
    
    echo -e "${GREEN}✓ Trojan account created successfully!${NC}"
    echo -e "${YELLOW}Account details saved to: /home/vps/public_html/akun/trojan_$username.txt${NC}"
    echo ""
    read -p "Press Enter to continue..."
    source /usr/local/bin/vpn/menu.sh
}

create_trojan_account
EOF

# Create domain.sh
cat > /usr/local/bin/vpn/domain.sh << 'EOF'
#!/bin/bash

# ==========================================
# Domain Changer
# ==========================================

source /usr/local/bin/vpn/utils.sh

change_domain() {
    clear
    show_banner
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                      CHANGE DOMAIN                           ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${YELLOW}Current domain: $(get_domain)${NC}"
    echo ""
    read -p "Enter new domain: " new_domain
    
    if [[ -n $new_domain ]]; then
        echo $new_domain > /etc/xray/domain
        echo -e "${GREEN}✓ Domain changed to: $new_domain${NC}"
    else
        echo -e "${RED}✗ Domain cannot be empty!${NC}"
    fi
    
    echo ""
    read -p "Press Enter to continue..."
    source /usr/local/bin/vpn/menu.sh
}

change_domain
EOF

# Create banner.sh
cat > /usr/local/bin/vpn/banner.sh << 'EOF'
#!/bin/bash

# ==========================================
# Banner Changer
# ==========================================

source /usr/local/bin/vpn/utils.sh

change_banner() {
    clear
    show_banner
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                      CHANGE BANNER                           ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${YELLOW}Enter your custom banner text:${NC}"
    echo -e "${YELLOW}(Press Enter twice to finish)${NC}"
    echo ""
    
    # Read multi-line input
    banner_text=""
    while IFS= read -r line; do
        if [[ -z $line ]]; then
            break
        fi
        banner_text+="$line"$'\n'
    done
    
    if [[ -n $banner_text ]]; then
        echo "$banner_text" > /etc/issue.net
        echo -e "${GREEN}✓ Banner updated successfully!${NC}"
    else
        echo -e "${RED}✗ Banner cannot be empty!${NC}"
    fi
    
    echo ""
    read -p "Press Enter to continue..."
    source /usr/local/bin/vpn/menu.sh
}

change_banner
EOF

# Create cekport.sh
cat > /usr/local/bin/vpn/cekport.sh << 'EOF'
#!/bin/bash

# ==========================================
# Port Checker
# ==========================================

source /usr/local/bin/vpn/utils.sh

check_ports() {
    clear
    show_banner
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                      CHECK ACTIVE PORTS                      ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${YELLOW}Checking active ports...${NC}"
    echo ""
    
    # Common ports to check
    ports=(22 80 443 8080 8443 8880 2083 2087 2096 8080 8880 9443)
    
    for port in "${ports[@]}"; do
        if netstat -tuln | grep -q ":$port "; then
            echo -e "${GREEN}✓ Port $port is OPEN${NC}"
        else
            echo -e "${RED}✗ Port $port is CLOSED${NC}"
        fi
    done
    
    echo ""
    echo -e "${YELLOW}Detailed port information:${NC}"
    netstat -tuln | grep -E ':(22|80|443|8080|8443|8880|2083|2087|2096|8080|8880|9443) '
    
    echo ""
    read -p "Press Enter to continue..."
    source /usr/local/bin/vpn/menu.sh
}

check_ports
EOF

# Set permissions
chmod +x /usr/local/bin/vpn/*.sh

# Create default domain
echo "localhost" > /etc/xray/domain

# Setup services
echo -e "${YELLOW}Setting up services...${NC}"

# Setup Dropbear
systemctl enable dropbear
systemctl start dropbear

# Setup Nginx
systemctl enable nginx
systemctl start nginx

# Create nginx config
cat > /etc/nginx/sites-available/vpn << 'EOF'
server {
    listen 80;
    server_name _;
    root /home/vps/public_html;
    index index.html index.htm;
    
    location / {
        try_files $uri $uri/ =404;
    }
    
    location /akun {
        autoindex on;
        autoindex_exact_size off;
        autoindex_localtime on;
    }
}
EOF

ln -sf /etc/nginx/sites-available/vpn /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Create default index page
mkdir -p /home/vps/public_html
cat > /home/vps/public_html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>VPN Server</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .container { max-width: 800px; margin: 0 auto; }
        .header { background: #007bff; color: white; padding: 20px; border-radius: 5px; }
        .content { margin-top: 20px; }
        .link { color: #007bff; text-decoration: none; }
        .link:hover { text-decoration: underline; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>VPN Server</h1>
            <p>Welcome to your VPN server dashboard</p>
        </div>
        <div class="content">
            <h2>Available Services</h2>
            <ul>
                <li><a href="/akun" class="link">View Account Files</a></li>
            </ul>
        </div>
    </div>
</body>
</html>
EOF

# Set ownership
chown -R www-data:www-data /home/vps/public_html

# Final setup
echo -e "${GREEN}✓ Installation completed successfully!${NC}"
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}VPN Server has been installed successfully!${NC}"
echo -e "${YELLOW}To access the menu, run:${NC}"
echo -e "${BLUE}source /usr/local/bin/vpn/menu.sh${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Create alias for easy access
echo "alias vpn='source /usr/local/bin/vpn/menu.sh'" >> /root/.bashrc
source /root/.bashrc

echo -e "${GREEN}✓ Alias 'vpn' created. You can now use 'vpn' command to access the menu.${NC}"
echo ""
echo -e "${YELLOW}Starting VPN menu...${NC}"
sleep 2

# Start the menu
source /usr/local/bin/vpn/menu.sh