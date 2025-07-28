#!/bin/bash

# SSL Auto Install Script
# Script untuk menginstall SSL certificate secara otomatis

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

print_status "Memulai instalasi SSL certificate..."

# Get domain name
read -p "Masukkan domain name (contoh: example.com): " DOMAIN_NAME

if [ -z "$DOMAIN_NAME" ]; then
    print_error "Domain name harus diisi"
    exit 1
fi

# Check if domain is configured in nginx
if [ ! -f "/etc/nginx/sites-available/$DOMAIN_NAME" ]; then
    print_error "Domain $DOMAIN_NAME tidak ditemukan di konfigurasi Nginx"
    echo "Pastikan domain sudah dikonfigurasi dengan benar"
    exit 1
fi

# Check if certbot is installed
if ! command -v certbot &> /dev/null; then
    print_error "Certbot tidak ditemukan. Install terlebih dahulu dengan:"
    echo "apt install -y certbot python3-certbot-nginx"
    exit 1
fi

# Check if domain is accessible
print_status "Mengecek akses domain..."
if ! curl -s --head "$DOMAIN_NAME" > /dev/null; then
    print_warning "Domain $DOMAIN_NAME tidak dapat diakses"
    echo "Pastikan:"
    echo "1. Domain sudah mengarah ke IP server ini"
    echo "2. Firewall mengizinkan port 80 dan 443"
    echo "3. Nginx berjalan dengan baik"
    read -p "Lanjutkan tetap? (y/n): " CONTINUE
    if [[ $CONTINUE != "y" && $CONTINUE != "Y" ]]; then
        exit 1
    fi
fi

# Install SSL certificate
print_status "Menginstall SSL certificate untuk $DOMAIN_NAME..."
certbot --nginx -d $DOMAIN_NAME -d www.$DOMAIN_NAME --non-interactive --agree-tos --email admin@$DOMAIN_NAME

if [ $? -eq 0 ]; then
    print_success "SSL certificate berhasil diinstall!"
    
    # Test SSL
    print_status "Mengecek SSL certificate..."
    echo | openssl s_client -servername $DOMAIN_NAME -connect $DOMAIN_NAME:443 2>/dev/null | openssl x509 -noout -dates
    
    # Show certificate info
    print_status "Informasi SSL certificate:"
    certbot certificates
    
    # Test HTTPS redirect
    print_status "Mengecek redirect HTTPS..."
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$DOMAIN_NAME)
    HTTPS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://$DOMAIN_NAME)
    
    echo "HTTP Status: $HTTP_STATUS"
    echo "HTTPS Status: $HTTPS_STATUS"
    
    if [ "$HTTPS_STATUS" = "200" ]; then
        print_success "HTTPS berfungsi dengan baik!"
    else
        print_warning "HTTPS mungkin belum berfungsi dengan baik"
    fi
    
    # Setup auto-renewal
    print_status "Mengatur auto-renewal SSL..."
    if ! crontab -l | grep -q "certbot renew"; then
        echo "0 12 * * * /usr/bin/certbot renew --quiet" | crontab -
        print_success "Auto-renewal SSL berhasil diatur"
    else
        print_status "Auto-renewal SSL sudah diatur sebelumnya"
    fi
    
    echo ""
    echo "=== INFORMASI SSL ==="
    echo "Domain: $DOMAIN_NAME"
    echo "SSL Provider: Let's Encrypt"
    echo "Auto-renewal: Setiap hari jam 12:00"
    echo ""
    echo "URL:"
    echo "- HTTP: http://$DOMAIN_NAME"
    echo "- HTTPS: https://$DOMAIN_NAME"
    echo ""
    echo "Test SSL:"
    echo "- https://www.ssllabs.com/ssltest/analyze.html?d=$DOMAIN_NAME"
    echo ""
    
else
    print_error "Gagal menginstall SSL certificate"
    echo ""
    echo "Kemungkinan penyebab:"
    echo "1. Domain belum mengarah ke IP server"
    echo "2. Firewall memblokir port 80/443"
    echo "3. Nginx tidak berjalan"
    echo "4. DNS belum terpropagasi"
    echo ""
    echo "Solusi:"
    echo "1. Tunggu DNS terpropagasi (bisa 24-48 jam)"
    echo "2. Pastikan domain mengarah ke IP server"
    echo "3. Cek status Nginx: systemctl status nginx"
    echo "4. Cek firewall: ufw status"
    echo ""
fi