#!/bin/bash

# Laravel Auto Install Script
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

print_status "Memulai instalasi Laravel..."

# Get project name
read -p "Masukkan nama project Laravel: " PROJECT_NAME

if [ -z "$PROJECT_NAME" ]; then
    print_warning "Nama project tidak diisi, menggunakan 'laravel-app'"
    PROJECT_NAME="laravel-app"
fi

# Get domain name
read -p "Masukkan domain name (contoh: example.com): " DOMAIN_NAME

if [ -z "$DOMAIN_NAME" ]; then
    print_warning "Domain tidak diisi, menggunakan localhost"
    DOMAIN_NAME="localhost"
fi

# Create database for Laravel
print_status "Membuat database Laravel..."
DB_NAME="laravel_${PROJECT_NAME}"
DB_USER="laravel_user"
DB_PASS=$(openssl rand -base64 12)

mysql -u root -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;"
mysql -u root -e "CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
mysql -u root -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"
mysql -u root -e "FLUSH PRIVILEGES;"

print_success "Database Laravel berhasil dibuat"

# Create nginx configuration for Laravel
print_status "Membuat konfigurasi Nginx untuk Laravel..."
cat > /etc/nginx/sites-available/$DOMAIN_NAME << EOF
server {
    listen 80;
    server_name $DOMAIN_NAME www.$DOMAIN_NAME;
    root /var/www/$DOMAIN_NAME/public;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
EOF

# Create website directory
mkdir -p /var/www/$DOMAIN_NAME
cd /var/www/$DOMAIN_NAME

# Install Laravel via Composer
print_status "Menginstall Laravel via Composer..."
composer create-project laravel/laravel $PROJECT_NAME --prefer-dist
mv $PROJECT_NAME/* .
mv $PROJECT_NAME/.* . 2>/dev/null || true
rmdir $PROJECT_NAME

# Set permissions
chown -R www-data:www-data /var/www/$DOMAIN_NAME
chmod -R 755 /var/www/$DOMAIN_NAME
chmod -R 775 storage bootstrap/cache

# Configure Laravel environment
print_status "Mengkonfigurasi environment Laravel..."
cp .env.example .env

# Generate application key
php artisan key:generate

# Update .env file with database configuration
sed -i "s/DB_DATABASE=.*/DB_DATABASE=$DB_NAME/" .env
sed -i "s/DB_USERNAME=.*/DB_USERNAME=$DB_USER/" .env
sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=$DB_PASS/" .env
sed -i "s/APP_URL=.*/APP_URL=http:\/\/$DOMAIN_NAME/" .env

# Install dependencies and optimize
print_status "Menginstall dependencies dan mengoptimasi..."
composer install --optimize-autoloader --no-dev
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Enable site
ln -s /etc/nginx/sites-available/$DOMAIN_NAME /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
systemctl reload nginx

print_success "Laravel berhasil diinstall!"

echo ""
echo "=== INFORMASI LARAVEL ==="
echo "URL: http://$DOMAIN_NAME"
echo "Project Name: $PROJECT_NAME"
echo "Database Name: $DB_NAME"
echo "Database User: $DB_USER"
echo "Database Password: $DB_PASS"
echo ""
echo "Perintah Berguna:"
echo "- Masuk ke direktori: cd /var/www/$DOMAIN_NAME"
echo "- Jalankan migration: php artisan migrate"
echo "- Clear cache: php artisan cache:clear"
echo "- Restart queue: php artisan queue:restart"
echo ""
echo "Langkah selanjutnya:"
echo "1. Akses http://$DOMAIN_NAME"
echo "2. Jalankan migration jika diperlukan"
echo "3. Install SSL dengan: certbot --nginx -d $DOMAIN_NAME"
echo ""