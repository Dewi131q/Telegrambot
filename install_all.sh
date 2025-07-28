#!/bin/bash

# Master Auto Install Script
# Script untuk menginstall semua komponen VPS sekaligus

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   print_error "Script ini harus dijalankan sebagai root (sudo)"
   exit 1
fi

echo ""
echo "=========================================="
echo "        VPS MASTER AUTO INSTALLER"
echo "=========================================="
echo ""

print_status "Script ini akan menginstall semua komponen VPS secara otomatis"
echo ""

# Get user preferences
read -p "Apakah Anda ingin menginstall WordPress? (y/n): " INSTALL_WORDPRESS
read -p "Apakah Anda ingin menginstall Laravel? (y/n): " INSTALL_LARAVEL
read -p "Apakah Anda ingin menginstall Node.js app? (y/n): " INSTALL_NODEJS
read -p "Apakah Anda ingin menginstall SSL certificate? (y/n): " INSTALL_SSL

# Get domain name
read -p "Masukkan domain name (contoh: example.com): " DOMAIN_NAME

if [ -z "$DOMAIN_NAME" ]; then
    print_warning "Domain tidak diisi, menggunakan localhost"
    DOMAIN_NAME="localhost"
fi

echo ""
print_status "Memulai instalasi..."

# Step 1: Install VPS base
print_status "Step 1: Menginstall VPS base..."
./vps_auto_install.sh

if [ $? -ne 0 ]; then
    print_error "Gagal menginstall VPS base"
    exit 1
fi

print_success "VPS base berhasil diinstall!"

# Step 2: Install WordPress if requested
if [[ $INSTALL_WORDPRESS == "y" || $INSTALL_WORDPRESS == "Y" ]]; then
    print_status "Step 2: Menginstall WordPress..."
    
    # Create temporary input file for WordPress script
    cat > /tmp/wordpress_input.txt << EOF
$DOMAIN_NAME
EOF
    
    ./install_wordpress.sh < /tmp/wordpress_input.txt
    
    if [ $? -eq 0 ]; then
        print_success "WordPress berhasil diinstall!"
    else
        print_warning "WordPress gagal diinstall, lanjutkan ke step berikutnya"
    fi
    
    rm -f /tmp/wordpress_input.txt
fi

# Step 3: Install Laravel if requested
if [[ $INSTALL_LARAVEL == "y" || $INSTALL_LARAVEL == "Y" ]]; then
    print_status "Step 3: Menginstall Laravel..."
    
    # Create temporary input file for Laravel script
    cat > /tmp/laravel_input.txt << EOF
laravel-app
$DOMAIN_NAME
EOF
    
    ./install_laravel.sh < /tmp/laravel_input.txt
    
    if [ $? -eq 0 ]; then
        print_success "Laravel berhasil diinstall!"
    else
        print_warning "Laravel gagal diinstall, lanjutkan ke step berikutnya"
    fi
    
    rm -f /tmp/laravel_input.txt
fi

# Step 4: Install Node.js app if requested
if [[ $INSTALL_NODEJS == "y" || $INSTALL_NODEJS == "Y" ]]; then
    print_status "Step 4: Menginstall Node.js app..."
    
    # Create temporary input file for Node.js script
    cat > /tmp/nodejs_input.txt << EOF
nodejs-app
$DOMAIN_NAME
3000
EOF
    
    ./install_nodejs_app.sh < /tmp/nodejs_input.txt
    
    if [ $? -eq 0 ]; then
        print_success "Node.js app berhasil diinstall!"
    else
        print_warning "Node.js app gagal diinstall, lanjutkan ke step berikutnya"
    fi
    
    rm -f /tmp/nodejs_input.txt
fi

# Step 5: Fix permissions
print_status "Step 5: Memperbaiki permissions..."
./fix_permissions.sh

# Step 6: Install SSL if requested
if [[ $INSTALL_SSL == "y" || $INSTALL_SSL == "Y" ]]; then
    print_status "Step 6: Menginstall SSL certificate..."
    
    # Create temporary input file for SSL script
    cat > /tmp/ssl_input.txt << EOF
$DOMAIN_NAME
y
EOF
    
    ./install_ssl.sh < /tmp/ssl_input.txt
    
    if [ $? -eq 0 ]; then
        print_success "SSL certificate berhasil diinstall!"
    else
        print_warning "SSL certificate gagal diinstall"
    fi
    
    rm -f /tmp/ssl_input.txt
fi

# Step 7: Final status check
print_status "Step 7: Mengecek status akhir..."
./check_status.sh

echo ""
echo "=========================================="
echo "        INSTALASI SELESAI!"
echo "=========================================="
echo ""

print_success "Semua komponen berhasil diinstall!"

echo "=== RINGKASAN INSTALASI ==="
echo "Domain: $DOMAIN_NAME"
echo "IP Address: $(curl -s ifconfig.me)"
echo ""

if [[ $INSTALL_WORDPRESS == "y" || $INSTALL_WORDPRESS == "Y" ]]; then
    echo "✅ WordPress: http://$DOMAIN_NAME"
fi

if [[ $INSTALL_LARAVEL == "y" || $INSTALL_LARAVEL == "Y" ]]; then
    echo "✅ Laravel: http://$DOMAIN_NAME"
fi

if [[ $INSTALL_NODEJS == "y" || $INSTALL_NODEJS == "Y" ]]; then
    echo "✅ Node.js App: http://$DOMAIN_NAME"
fi

if [[ $INSTALL_SSL == "y" || $INSTALL_SSL == "Y" ]]; then
    echo "✅ SSL Certificate: https://$DOMAIN_NAME"
fi

echo ""
echo "=== PERINTAH BERGUNA ==="
echo "Check status: ./check_status.sh"
echo "Backup manual: ./backup-sites.sh"
echo "Monitor sistem: system-monitor.sh"
echo "Restart Nginx: systemctl restart nginx"
echo "Restart PHP: systemctl restart php8.1-fpm"
echo "Restart MariaDB: systemctl restart mariadb"
echo ""

echo "=== PENTING ==="
echo "1. Simpan password database yang di-generate"
echo "2. Hapus file info.php setelah selesai setup"
echo "3. Konfigurasi domain DNS mengarah ke IP server"
echo "4. Periksa firewall dan keamanan"
echo "5. Setup backup otomatis"
echo ""

print_success "VPS siap digunakan!"
echo ""