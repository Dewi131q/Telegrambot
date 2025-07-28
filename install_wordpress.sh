#!/bin/bash

# WordPress Auto Install Script
# Jalankan script ini setelah vps_auto_install.sh selesai

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

print_status "Memulai instalasi WordPress..."

# Get domain name
read -p "Masukkan domain name (contoh: example.com): " DOMAIN_NAME

if [ -z "$DOMAIN_NAME" ]; then
    print_warning "Domain tidak diisi, menggunakan localhost"
    DOMAIN_NAME="localhost"
fi

# Create database for WordPress
print_status "Membuat database WordPress..."
DB_NAME="wordpress"
DB_USER="wp_user"
DB_PASS=$(openssl rand -base64 12)

mysql -u root -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;"
mysql -u root -e "CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
mysql -u root -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"
mysql -u root -e "FLUSH PRIVILEGES;"

print_success "Database WordPress berhasil dibuat"

# Create nginx configuration for WordPress
print_status "Membuat konfigurasi Nginx untuk WordPress..."
cat > /etc/nginx/sites-available/$DOMAIN_NAME << EOF
server {
    listen 80;
    server_name $DOMAIN_NAME www.$DOMAIN_NAME;
    root /var/www/$DOMAIN_NAME;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }

    location = /favicon.ico { log_not_found off; access_log off; }
    location = /robots.txt { log_not_found off; access_log off; allow all; }
    location ~* \.(css|gif|ico|jpeg|jpg|js|png)$ {
        expires 1y;
        log_not_found off;
    }
}
EOF

# Create website directory
mkdir -p /var/www/$DOMAIN_NAME
cd /var/www/$DOMAIN_NAME

# Download WordPress
print_status "Mendownload WordPress..."
wget https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz
mv wordpress/* .
rm -rf wordpress latest.tar.gz

# Set permissions
chown -R www-data:www-data /var/www/$DOMAIN_NAME
chmod -R 755 /var/www/$DOMAIN_NAME

# Create wp-config.php
print_status "Membuat file konfigurasi WordPress..."
cp wp-config-sample.php wp-config.php

# Generate WordPress keys
WP_KEYS=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)

# Update wp-config.php
sed -i "s/define( 'DB_NAME', 'database_name_here' );/define( 'DB_NAME', '$DB_NAME' );/" wp-config.php
sed -i "s/define( 'DB_USER', 'username_here' );/define( 'DB_USER', '$DB_USER' );/" wp-config.php
sed -i "s/define( 'DB_PASSWORD', 'password_here' );/define( 'DB_PASSWORD', '$DB_PASS' );/" wp-config.php
sed -i "s/define( 'DB_HOST', 'localhost' );/define( 'DB_HOST', 'localhost' );/" wp-config.php

# Replace WordPress keys
sed -i '/define( '\''AUTH_KEY'\'',/,$d' wp-config.php
echo "$WP_KEYS" >> wp-config.php
echo "define( 'WP_TABLE_PREFIX', 'wp_' );" >> wp-config.php

# Enable site
ln -s /etc/nginx/sites-available/$DOMAIN_NAME /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
systemctl reload nginx

print_success "WordPress berhasil diinstall!"

echo ""
echo "=== INFORMASI WORDPRESS ==="
echo "URL: http://$DOMAIN_NAME"
echo "Database Name: $DB_NAME"
echo "Database User: $DB_USER"
echo "Database Password: $DB_PASS"
echo ""
echo "Langkah selanjutnya:"
echo "1. Akses http://$DOMAIN_NAME"
echo "2. Selesaikan setup WordPress"
echo "3. Install SSL dengan: certbot --nginx -d $DOMAIN_NAME"
echo ""