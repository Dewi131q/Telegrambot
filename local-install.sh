#!/bin/bash

# Local VPN Auto Installer
# This script installs from local directory instead of downloading from GitHub

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored text
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   print_error "Script ini harus dijalankan sebagai root!"
   exit 1
fi

# Check OS compatibility
check_os() {
    if [[ -f /etc/debian_version ]]; then
        OS="debian"
        VERSION=$(cat /etc/debian_version)
        print_status "Detected Debian/Ubuntu: $VERSION"
    else
        print_error "OS tidak didukung! Script ini hanya mendukung Debian/Ubuntu."
        exit 1
    fi
}

# Create directories
create_directories() {
    print_status "Membuat direktori yang diperlukan..."
    mkdir -p /etc/vpn-script/{config,akun,log}
    mkdir -p /var/lib/vpn-script
    mkdir -p /usr/local/bin/vpn-script
}

# Install dependencies
install_dependencies() {
    print_status "Installing dependencies..."
    apt update -y
    apt install -y wget curl unzip zip tar jq bc
    apt install -y software-properties-common apt-transport-https ca-certificates
    apt install -y gnupg lsb-release
    apt install -y net-tools dnsutils
    apt install -y iptables iptables-persistent
    apt install -y build-essential
    apt install -y htop vnstat
    apt install -y nginx
    apt install -y dropbear-bin
    apt install -y gzip
}

# Install Xray
install_xray() {
    print_status "Installing Xray-core..."
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
    systemctl enable xray
    systemctl start xray
}

# Configure services
configure_services() {
    print_status "Configuring services..."
    
    # Configure Dropbear
    echo 'DROPBEAR_PORT=143' > /etc/default/dropbear
    echo 'DROPBEAR_EXTRA_ARGS="-p 143"' >> /etc/default/dropbear
    systemctl enable dropbear
    systemctl restart dropbear
    
    # Configure Nginx
    rm -f /etc/nginx/sites-enabled/default
    cat > /etc/nginx/sites-available/vpn << 'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name _;
    
    location / {
        return 200 'VPN Server is Running!';
        add_header Content-Type text/plain;
    }
    
    location /websocket {
        proxy_pass http://127.0.0.1:10000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
EOF
    
    ln -s /etc/nginx/sites-available/vpn /etc/nginx/sites-enabled/
    nginx -t && systemctl restart nginx
    systemctl enable nginx
}

# Configure firewall
configure_firewall() {
    print_status "Configuring firewall..."
    
    # Basic iptables rules
    iptables -F
    iptables -A INPUT -i lo -j ACCEPT
    iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    iptables -A INPUT -p tcp --dport 22 -j ACCEPT
    iptables -A INPUT -p tcp --dport 143 -j ACCEPT
    iptables -A INPUT -p tcp --dport 80 -j ACCEPT
    iptables -A INPUT -p tcp --dport 443 -j ACCEPT
    iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
    iptables -A INPUT -p tcp --dport 8443 -j ACCEPT
    iptables -A INPUT -p tcp --dport 2096 -j ACCEPT
    iptables -A INPUT -p tcp --dport 10000 -j ACCEPT
    iptables -A INPUT -j DROP
    
    # Save rules
    iptables-save > /etc/iptables/rules.v4
}

# Copy scripts to destination
copy_scripts() {
    print_status "Copying VPN scripts..."
    
    local current_dir=$(pwd)
    
    # List of required scripts
    local scripts=("menu.sh" "utils.sh" "ssh.sh" "vless.sh" "vmess.sh" "trojan.sh" "domain.sh" "banner.sh" "cekport.sh")
    
    for script in "${scripts[@]}"; do
        if [[ -f "$current_dir/$script" ]]; then
            cp "$current_dir/$script" "/usr/local/bin/vpn-script/"
            print_status "Copied $script"
        else
            print_warning "Script $script not found in current directory"
        fi
    done
    
    # Make all scripts executable
    chmod +x /usr/local/bin/vpn-script/*.sh
    
    # Create symlink for easy access
    ln -sf /usr/local/bin/vpn-script/menu.sh /usr/local/bin/vpn-menu
}

# Setup domain
setup_domain() {
    print_status "Setting up domain..."
    
    # Get public IP
    PUBLIC_IP=$(curl -s https://api.ipify.org)
    
    echo -e "${CYAN}========================================${NC}"
    echo -e "${YELLOW}          SETUP DOMAIN${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "IP Public VPS: ${GREEN}$PUBLIC_IP${NC}"
    echo ""
    read -p "Masukkan domain (kosongkan untuk menggunakan IP): " DOMAIN
    
    if [[ -z "$DOMAIN" ]]; then
        DOMAIN=$PUBLIC_IP
        print_warning "Menggunakan IP sebagai domain: $DOMAIN"
    else
        print_status "Domain yang akan digunakan: $DOMAIN"
    fi
    
    # Save domain
    echo "$DOMAIN" > /etc/vpn-script/domain.txt
}

# Create initial Xray config
create_xray_config() {
    print_status "Creating initial Xray configuration..."
    
    DOMAIN=$(cat /etc/vpn-script/domain.txt)
    
    cat > /usr/local/etc/xray/config.json << EOF
{
    "log": {
        "loglevel": "warning"
    },
    "inbounds": [
        {
            "port": 8080,
            "protocol": "vless",
            "settings": {
                "clients": [],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "ws",
                "wsSettings": {
                    "path": "/vless"
                }
            }
        },
        {
            "port": 8443,
            "protocol": "vmess",
            "settings": {
                "clients": []
            },
            "streamSettings": {
                "network": "ws",
                "wsSettings": {
                    "path": "/vmess"
                }
            }
        },
        {
            "port": 2096,
            "protocol": "trojan",
            "settings": {
                "clients": []
            },
            "streamSettings": {
                "network": "ws",
                "wsSettings": {
                    "path": "/trojan"
                }
            }
        },
        {
            "port": 10000,
            "protocol": "shadowsocks",
            "settings": {
                "method": "aes-256-gcm",
                "password": "vpn-script-ws",
                "network": "tcp,udp"
            }
        }
    ],
    "outbounds": [
        {
            "protocol": "freedom"
        }
    ]
}
EOF

    systemctl restart xray
}

# Main installation function
main() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}       VPN AUTO INSTALLER${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "${YELLOW}Local Installation Mode${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    
    print_status "Starting VPN Server installation..."
    
    check_os
    create_directories
    install_dependencies
    install_xray
    configure_services
    configure_firewall
    copy_scripts
    setup_domain
    create_xray_config
    
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}     INSTALLATION SUCCESSFUL!${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}✓ Xray-core installed${NC}"
    echo -e "${GREEN}✓ Dropbear SSH (Port 143)${NC}"
    echo -e "${GREEN}✓ Nginx Web Server${NC}"
    echo -e "${GREEN}✓ Firewall configured${NC}"
    echo -e "${GREEN}✓ VPN Scripts installed${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    echo -e "To access VPN menu, run:"
    echo -e "${GREEN}vpn-menu${NC}"
    echo ""
    echo -e "Or:"
    echo -e "${GREEN}/usr/local/bin/vpn-script/menu.sh${NC}"
    echo ""
    print_status "Installation completed! Server is ready to use."
}

# Run main function
main