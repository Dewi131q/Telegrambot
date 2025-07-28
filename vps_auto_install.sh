#!/bin/bash

# VPS Auto Install Script for Ubuntu 20.04
# Script ini akan menginstall dan mengkonfigurasi VPS secara otomatis

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

print_status "Memulai auto install VPS Ubuntu 20.04..."

# Update system
print_status "Mengupdate sistem..."
apt update && apt upgrade -y
print_success "Sistem berhasil diupdate"

# Install essential packages
print_status "Menginstall paket-paket penting..."
apt install -y curl wget git unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release

# Install UFW Firewall
print_status "Menginstall dan mengkonfigurasi UFW Firewall..."
apt install -y ufw
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable
print_success "UFW Firewall berhasil dikonfigurasi"

# Install Fail2ban
print_status "Menginstall Fail2ban untuk keamanan..."
apt install -y fail2ban
systemctl enable fail2ban
systemctl start fail2ban
print_success "Fail2ban berhasil diinstall"

# Configure SSH security
print_status "Mengkonfigurasi keamanan SSH..."
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

# Edit SSH config for better security
cat > /etc/ssh/sshd_config << EOF
Port 22
Protocol 2
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_dsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key
UsePrivilegeSeparation yes
KeyRegenerationInterval 3600
ServerKeyBits 1024
SyslogFacility AUTH
LogLevel INFO
LoginGraceTime 120
PermitRootLogin no
StrictModes yes
RSAAuthentication yes
PubkeyAuthentication yes
AuthorizedKeysFile %h/.ssh/authorized_keys
IgnoreRhosts yes
RhostsRSAAuthentication no
HostbasedAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
PasswordAuthentication yes
X11Forwarding yes
X11DisplayOffset 10
PrintMotd no
PrintLastLog yes
TCPKeepAlive yes
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
UsePAM yes
EOF

systemctl restart ssh
print_success "SSH berhasil dikonfigurasi"

# Install Nginx
print_status "Menginstall Nginx..."
apt install -y nginx
systemctl enable nginx
systemctl start nginx
print_success "Nginx berhasil diinstall"

# Install PHP 8.1
print_status "Menginstall PHP 8.1..."
add-apt-repository ppa:ondrej/php -y
apt update
apt install -y php8.1-fpm php8.1-mysql php8.1-curl php8.1-gd php8.1-intl php8.1-mbstring php8.1-xml php8.1-zip php8.1-bcmath php8.1-soap php8.1-xmlrpc php8.1-common
systemctl enable php8.1-fpm
systemctl start php8.1-fpm
print_success "PHP 8.1 berhasil diinstall"

# Install MySQL/MariaDB
print_status "Menginstall MariaDB..."
apt install -y mariadb-server mariadb-client
systemctl enable mariadb
systemctl start mariadb

# Secure MySQL installation
mysql_secure_installation << EOF

y
1
2
y
y
y
y
EOF

print_success "MariaDB berhasil diinstall dan dikonfigurasi"

# Install Node.js and npm
print_status "Menginstall Node.js dan npm..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs
print_success "Node.js dan npm berhasil diinstall"

# Install PM2 for Node.js process management
print_status "Menginstall PM2..."
npm install -g pm2
print_success "PM2 berhasil diinstall"

# Install Certbot for SSL
print_status "Menginstall Certbot untuk SSL..."
apt install -y certbot python3-certbot-nginx
print_success "Certbot berhasil diinstall"

# Create default nginx configuration
print_status "Membuat konfigurasi Nginx default..."
cat > /etc/nginx/sites-available/default << EOF
server {
    listen 80;
    server_name _;
    root /var/www/html;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

systemctl reload nginx
print_success "Konfigurasi Nginx default berhasil dibuat"

# Create info page
print_status "Membuat halaman info..."
cat > /var/www/html/info.php << EOF
<?php
phpinfo();
?>
EOF

# Set proper permissions
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html
print_success "Halaman info berhasil dibuat"

# Install Composer
print_status "Menginstall Composer..."
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer
print_success "Composer berhasil diinstall"

# Create system monitoring script
print_status "Membuat script monitoring sistem..."
cat > /usr/local/bin/system-monitor.sh << 'EOF'
#!/bin/bash
echo "=== System Information ==="
echo "Uptime: $(uptime)"
echo "Memory Usage:"
free -h
echo "Disk Usage:"
df -h
echo "CPU Load:"
top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}'
echo "Active Connections:"
netstat -an | grep :80 | wc -l
EOF

chmod +x /usr/local/bin/system-monitor.sh
print_success "Script monitoring sistem berhasil dibuat"

# Create backup script
print_status "Membuat script backup..."
cat > /usr/local/bin/backup-sites.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/backup"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup websites
tar -czf $BACKUP_DIR/websites_$DATE.tar.gz /var/www/html/

# Backup databases
mysqldump --all-databases > $BACKUP_DIR/databases_$DATE.sql

# Keep only last 7 days of backups
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete

echo "Backup completed: $DATE"
EOF

chmod +x /usr/local/bin/backup-sites.sh
print_success "Script backup berhasil dibuat"

# Create cron job for backup
echo "0 2 * * * /usr/local/bin/backup-sites.sh" | crontab -

# Final system cleanup
print_status "Melakukan cleanup sistem..."
apt autoremove -y
apt autoclean
print_success "Cleanup sistem selesai"

# Display final information
echo ""
print_success "=== INSTALASI SELESAI ==="
echo ""
echo "Informasi Server:"
echo "- IP Address: $(curl -s ifconfig.me)"
echo "- SSH Port: 22"
echo "- Web Server: Nginx + PHP 8.1"
echo "- Database: MariaDB"
echo "- Node.js: $(node --version)"
echo "- PM2: $(pm2 --version)"
echo ""
echo "Akses Web Server:"
echo "- HTTP: http://$(curl -s ifconfig.me)"
echo "- PHP Info: http://$(curl -s ifconfig.me)/info.php"
echo ""
echo "Perintah Berguna:"
echo "- Monitor sistem: system-monitor.sh"
echo "- Backup manual: backup-sites.sh"
echo "- Restart Nginx: systemctl restart nginx"
echo "- Restart PHP: systemctl restart php8.1-fpm"
echo "- Restart MariaDB: systemctl restart mariadb"
echo ""
print_warning "Jangan lupa untuk:"
echo "1. Mengubah password root MySQL"
echo "2. Mengkonfigurasi domain dan SSL"
echo "3. Menghapus file info.php setelah selesai"
echo "4. Mengatur firewall sesuai kebutuhan"
echo ""
print_success "VPS siap digunakan!"