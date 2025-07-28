#!/bin/bash

# Auto Install VPN Script
# Supported OS: Debian 10/11, Ubuntu 20.04
# Created by VPN-Installer

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

# Update system
update_system() {
    print_status "Memperbarui sistem..."
    apt update -y
    apt upgrade -y
}

# Install dependencies
install_dependencies() {
    print_status "Menginstall dependensi yang diperlukan..."
    
    # Essential packages
    apt install -y wget curl unzip zip tar
    apt install -y software-properties-common apt-transport-https ca-certificates
    apt install -y gnupg lsb-release
    
    # Network tools
    apt install -y net-tools dnsutils
    apt install -y iptables iptables-persistent
    
    # Development tools
    apt install -y build-essential
    
    # System monitoring
    apt install -y htop vnstat
    
    # Web server
    apt install -y nginx
    
    # SSH server enhancements
    apt install -y dropbear-bin
    
    # Compression tools
    apt install -y gzip
    
    print_status "Dependensi berhasil diinstall!"
}

# Install Xray
install_xray() {
    print_status "Menginstall Xray-core..."
    
    # Download and install Xray
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
    
    # Enable and start Xray service
    systemctl enable xray
    systemctl start xray
    
    print_status "Xray-core berhasil diinstall!"
}

# Configure Dropbear
configure_dropbear() {
    print_status "Mengkonfigurasi Dropbear SSH..."
    
    # Configure Dropbear on port 143
    echo 'DROPBEAR_PORT=143' > /etc/default/dropbear
    echo 'DROPBEAR_EXTRA_ARGS="-p 143"' >> /etc/default/dropbear
    
    # Enable and restart Dropbear
    systemctl enable dropbear
    systemctl restart dropbear
    
    print_status "Dropbear SSH dikonfigurasi pada port 143!"
}

# Configure Nginx
configure_nginx() {
    print_status "Mengkonfigurasi Nginx..."
    
    # Remove default config
    rm -f /etc/nginx/sites-enabled/default
    
    # Create VPN config
    cat > /etc/nginx/sites-available/vpn << EOF
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
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

    # Enable site
    ln -s /etc/nginx/sites-available/vpn /etc/nginx/sites-enabled/
    
    # Test and restart Nginx
    nginx -t && systemctl restart nginx
    systemctl enable nginx
    
    print_status "Nginx berhasil dikonfigurasi!"
}

# Configure firewall
configure_firewall() {
    print_status "Mengkonfigurasi firewall..."
    
    # Clear existing rules
    iptables -F
    iptables -X
    iptables -t nat -F
    iptables -t nat -X
    
    # Allow loopback
    iptables -A INPUT -i lo -j ACCEPT
    iptables -A OUTPUT -o lo -j ACCEPT
    
    # Allow established connections
    iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    
    # Allow SSH
    iptables -A INPUT -p tcp --dport 22 -j ACCEPT
    iptables -A INPUT -p tcp --dport 143 -j ACCEPT  # Dropbear
    
    # Allow HTTP/HTTPS
    iptables -A INPUT -p tcp --dport 80 -j ACCEPT
    iptables -A INPUT -p tcp --dport 443 -j ACCEPT
    
    # Allow VPN ports
    iptables -A INPUT -p tcp --dport 8080 -j ACCEPT  # VLESS
    iptables -A INPUT -p tcp --dport 8443 -j ACCEPT  # VMess
    iptables -A INPUT -p tcp --dport 2096 -j ACCEPT  # Trojan
    iptables -A INPUT -p tcp --dport 10000 -j ACCEPT # WebSocket
    
    # Drop other traffic
    iptables -A INPUT -j DROP
    
    # Save rules
    iptables-save > /etc/iptables/rules.v4
    
    print_status "Firewall berhasil dikonfigurasi!"
}

# Download scripts
download_scripts() {
    print_status "Mendownload script VPN..."
    
    cd /usr/local/bin/vpn-script
    
    # Download all required scripts
    download_github_scripts
    
    # Make all scripts executable
    chmod +x *.sh
    
    # Create symlink for easy access
    ln -sf /usr/local/bin/vpn-script/menu.sh /usr/local/bin/vpn-menu
    
    print_status "Script berhasil didownload!"
}

# Download scripts from repository
download_github_scripts() {
    print_status "Downloading VPN scripts from repository..."
    
    local repo_url="https://raw.githubusercontent.com/username/vpn-auto-installer/main"
    
    # Download all scripts
    local scripts=("menu.sh" "utils.sh" "ssh.sh" "vless.sh" "vmess.sh" "trojan.sh" "domain.sh" "banner.sh" "cekport.sh")
    
    for script in "${scripts[@]}"; do
        if curl -s -o "$script" "$repo_url/$script"; then
            print_status "Downloaded $script"
        else
            print_warning "Failed to download $script, creating placeholder"
            create_placeholder_script "$script"
        fi
    done
}

# Create placeholder scripts if download fails
create_placeholder_script() {
    local script_name="$1"
    
    case "$script_name" in
        "menu.sh")
            cat > menu.sh << 'EOF'
#!/bin/bash
echo "VPN Menu - Script not fully installed"
echo "Please check your internet connection and try reinstalling"
EOF
            ;;
        "utils.sh")
            cat > utils.sh << 'EOF'
#!/bin/bash
# Basic utility functions
get_public_ip() { curl -s https://api.ipify.org; }
get_domain() { 
    if [[ -f /etc/vpn-script/domain.txt ]]; then
        cat /etc/vpn-script/domain.txt
    else
        get_public_ip
    fi
}
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "Script ini harus dijalankan sebagai root!"
        exit 1
    fi
}
EOF
            ;;
        *)
            cat > "$script_name" << 'EOF'
#!/bin/bash
echo "Script not available - please reinstall"
exit 1
EOF
            ;;
    esac
}

# Setup domain
setup_domain() {
    print_status "Setup domain..."
    
    # Get public IP
    PUBLIC_IP=$(curl -s https://api.ipify.org)
    
    # Ask for domain or use IP
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
    
    print_status "Domain berhasil disimpan!"
}

# Create initial configs
create_initial_configs() {
    print_status "Membuat konfigurasi awal..."
    
    DOMAIN=$(cat /etc/vpn-script/domain.txt)
    
    # Create Xray config
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

    # Restart Xray
    systemctl restart xray
    
    print_status "Konfigurasi awal berhasil dibuat!"
}

# Main installation function
main() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}       VPN AUTO INSTALLER${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "${YELLOW}Supported OS: Debian 10/11, Ubuntu 20.04${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    
    print_status "Memulai instalasi VPN Server..."
    
    check_os
    create_directories
    update_system
    install_dependencies
    install_xray
    configure_dropbear
    configure_nginx
    configure_firewall
    download_scripts
    setup_domain
    create_initial_configs
    
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}     INSTALASI BERHASIL!${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}✓ Xray-core terinstall${NC}"
    echo -e "${GREEN}✓ Dropbear SSH (Port 143)${NC}"
    echo -e "${GREEN}✓ Nginx Web Server${NC}"
    echo -e "${GREEN}✓ Firewall dikonfigurasi${NC}"
    echo -e "${GREEN}✓ Script VPN terdownload${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    echo -e "Untuk mengakses menu VPN, jalankan perintah:"
    echo -e "${GREEN}vpn-menu${NC}"
    echo ""
    echo -e "Atau:"
    echo -e "${GREEN}/usr/local/bin/vpn-script/menu.sh${NC}"
    echo ""
    print_status "Instalasi selesai! Server siap digunakan."
}

# Run main function
main