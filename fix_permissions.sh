#!/bin/bash

# Fix Permissions Script
# Jalankan script ini setelah install aplikasi web

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
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

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "\033[0;31m[ERROR]\033[0m Script ini harus dijalankan sebagai root (sudo)"
   exit 1
fi

print_status "Memperbaiki permission file..."

# Get domain name
read -p "Masukkan domain name: " DOMAIN_NAME

if [ -z "$DOMAIN_NAME" ]; then
    print_warning "Domain tidak diisi, menggunakan localhost"
    DOMAIN_NAME="localhost"
fi

# Check if directory exists
if [ ! -d "/var/www/$DOMAIN_NAME" ]; then
    print_error "Direktori /var/www/$DOMAIN_NAME tidak ditemukan"
    exit 1
fi

# Fix ownership
print_status "Memperbaiki ownership file..."
chown -R www-data:www-data /var/www/$DOMAIN_NAME

# Fix directory permissions
print_status "Memperbaiki permission direktori..."
find /var/www/$DOMAIN_NAME -type d -exec chmod 755 {} \;

# Fix file permissions
print_status "Memperbaiki permission file..."
find /var/www/$DOMAIN_NAME -type f -exec chmod 644 {} \;

# Special permissions for specific files
print_status "Mengatur permission khusus..."

# Make executable files executable
find /var/www/$DOMAIN_NAME -name "*.sh" -exec chmod 755 {} \;
find /var/www/$DOMAIN_NAME -name "*.py" -exec chmod 755 {} \;

# WordPress specific permissions
if [ -f "/var/www/$DOMAIN_NAME/wp-config.php" ]; then
    print_status "Mengatur permission WordPress..."
    chmod 640 /var/www/$DOMAIN_NAME/wp-config.php
    chown www-data:www-data /var/www/$DOMAIN_NAME/wp-config.php
    
    # WordPress upload directory
    if [ -d "/var/www/$DOMAIN_NAME/wp-content/uploads" ]; then
        chmod 775 /var/www/$DOMAIN_NAME/wp-content/uploads
        chown www-data:www-data /var/www/$DOMAIN_NAME/wp-content/uploads
    fi
    
    # WordPress cache directory
    if [ -d "/var/www/$DOMAIN_NAME/wp-content/cache" ]; then
        chmod 775 /var/www/$DOMAIN_NAME/wp-content/cache
        chown www-data:www-data /var/www/$DOMAIN_NAME/wp-content/cache
    fi
fi

# Laravel specific permissions
if [ -f "/var/www/$DOMAIN_NAME/artisan" ]; then
    print_status "Mengatur permission Laravel..."
    chmod 755 /var/www/$DOMAIN_NAME/artisan
    chown www-data:www-data /var/www/$DOMAIN_NAME/artisan
    
    # Laravel storage directory
    if [ -d "/var/www/$DOMAIN_NAME/storage" ]; then
        chmod -R 775 /var/www/$DOMAIN_NAME/storage
        chown -R www-data:www-data /var/www/$DOMAIN_NAME/storage
    fi
    
    # Laravel bootstrap/cache directory
    if [ -d "/var/www/$DOMAIN_NAME/bootstrap/cache" ]; then
        chmod -R 775 /var/www/$DOMAIN_NAME/bootstrap/cache
        chown -R www-data:www-data /var/www/$DOMAIN_NAME/bootstrap/cache
    fi
fi

# Node.js specific permissions
if [ -f "/var/www/$DOMAIN_NAME/package.json" ]; then
    print_status "Mengatur permission Node.js..."
    chmod 644 /var/www/$DOMAIN_NAME/package.json
    chown www-data:www-data /var/www/$DOMAIN_NAME/package.json
    
    # Node.js logs directory
    if [ -d "/var/www/$DOMAIN_NAME/logs" ]; then
        chmod -R 775 /var/www/$DOMAIN_NAME/logs
        chown -R www-data:www-data /var/www/$DOMAIN_NAME/logs
    fi
fi

# Fix .env file permissions
if [ -f "/var/www/$DOMAIN_NAME/.env" ]; then
    print_status "Mengatur permission .env file..."
    chmod 640 /var/www/$DOMAIN_NAME/.env
    chown www-data:www-data /var/www/$DOMAIN_NAME/.env
fi

# Fix .htaccess file permissions
if [ -f "/var/www/$DOMAIN_NAME/.htaccess" ]; then
    print_status "Mengatur permission .htaccess..."
    chmod 644 /var/www/$DOMAIN_NAME/.htaccess
    chown www-data:www-data /var/www/$DOMAIN_NAME/.htaccess
fi

# Fix nginx configuration permissions
print_status "Mengatur permission konfigurasi Nginx..."
chmod 644 /etc/nginx/sites-available/$DOMAIN_NAME
chown root:root /etc/nginx/sites-available/$DOMAIN_NAME

# Restart services
print_status "Restart service..."
systemctl reload nginx
systemctl reload php8.1-fpm

print_success "Permission berhasil diperbaiki!"

echo ""
echo "=== INFORMASI PERMISSION ==="
echo "Domain: $DOMAIN_NAME"
echo "Directory: /var/www/$DOMAIN_NAME"
echo "Owner: www-data:www-data"
echo "Directory permissions: 755"
echo "File permissions: 644"
echo ""
echo "Permission khusus:"
if [ -f "/var/www/$DOMAIN_NAME/wp-config.php" ]; then
    echo "- WordPress: wp-config.php (640)"
fi
if [ -f "/var/www/$DOMAIN_NAME/artisan" ]; then
    echo "- Laravel: artisan (755), storage (775), bootstrap/cache (775)"
fi
if [ -f "/var/www/$DOMAIN_NAME/package.json" ]; then
    echo "- Node.js: logs directory (775)"
fi
echo ""