#!/bin/bash

# Check Status Script
# Script untuk mengecek status semua service dan informasi sistem

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

echo ""
echo "=========================================="
echo "           VPS STATUS CHECKER"
echo "=========================================="
echo ""

# System Information
print_status "=== INFORMASI SISTEM ==="
echo "OS: $(lsb_release -d | cut -f2)"
echo "Kernel: $(uname -r)"
echo "Architecture: $(uname -m)"
echo "Uptime: $(uptime -p)"
echo "Load Average: $(uptime | awk -F'load average:' '{print $2}')"
echo ""

# Memory Information
print_status "=== INFORMASI MEMORY ==="
free -h
echo ""

# Disk Information
print_status "=== INFORMASI DISK ==="
df -h
echo ""

# Network Information
print_status "=== INFORMASI NETWORK ==="
echo "IP Address: $(curl -s ifconfig.me)"
echo "Hostname: $(hostname)"
echo ""

# Service Status
print_status "=== STATUS SERVICE ==="

# Check Nginx
if systemctl is-active --quiet nginx; then
    print_success "Nginx: Running"
else
    print_error "Nginx: Not running"
fi

# Check PHP-FPM
if systemctl is-active --quiet php8.1-fpm; then
    print_success "PHP-FPM: Running"
else
    print_error "PHP-FPM: Not running"
fi

# Check MariaDB
if systemctl is-active --quiet mariadb; then
    print_success "MariaDB: Running"
else
    print_error "MariaDB: Not running"
fi

# Check SSH
if systemctl is-active --quiet ssh; then
    print_success "SSH: Running"
else
    print_error "SSH: Not running"
fi

# Check UFW
if systemctl is-active --quiet ufw; then
    print_success "UFW Firewall: Running"
else
    print_warning "UFW Firewall: Not running"
fi

# Check Fail2ban
if systemctl is-active --quiet fail2ban; then
    print_success "Fail2ban: Running"
else
    print_warning "Fail2ban: Not running"
fi

echo ""

# Firewall Status
print_status "=== FIREWALL STATUS ==="
ufw status
echo ""

# Active Connections
print_status "=== KONEKSI AKTIF ==="
echo "SSH Connections: $(ss -tuln | grep :22 | wc -l)"
echo "HTTP Connections: $(ss -tuln | grep :80 | wc -l)"
echo "HTTPS Connections: $(ss -tuln | grep :443 | wc -l)"
echo ""

# PM2 Status (if Node.js apps are running)
if command -v pm2 &> /dev/null; then
    print_status "=== PM2 STATUS ==="
    pm2 list
    echo ""
fi

# Nginx Sites
print_status "=== NGINX SITES ==="
echo "Available sites:"
ls -la /etc/nginx/sites-available/
echo ""
echo "Enabled sites:"
ls -la /etc/nginx/sites-enabled/
echo ""

# Database Information
print_status "=== DATABASE INFORMATION ==="
echo "MariaDB Version: $(mysql --version)"
echo "Databases:"
mysql -u root -e "SHOW DATABASES;" 2>/dev/null || echo "Cannot connect to database"
echo ""

# SSL Certificates
print_status "=== SSL CERTIFICATES ==="
if command -v certbot &> /dev/null; then
    certbot certificates
else
    echo "Certbot not installed"
fi
echo ""

# Recent Logs
print_status "=== RECENT LOGS ==="
echo "Last 5 Nginx error logs:"
tail -5 /var/log/nginx/error.log 2>/dev/null || echo "No error logs found"
echo ""

echo "Last 5 PHP-FPM logs:"
tail -5 /var/log/php8.1-fpm.log 2>/dev/null || echo "No PHP-FPM logs found"
echo ""

# System Health
print_status "=== SYSTEM HEALTH ==="
echo "CPU Usage: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')%"
echo "Memory Usage: $(free | grep Mem | awk '{printf("%.2f%%", $3/$2 * 100.0)}')"
echo "Disk Usage: $(df / | awk 'NR==2 {print $5}')"
echo ""

# Recommendations
print_status "=== REKOMENDASI ==="
if [ $(free | grep Mem | awk '{print $3/$2 * 100.0}' | cut -d. -f1) -gt 80 ]; then
    print_warning "Memory usage is high. Consider upgrading RAM or optimizing applications."
fi

if [ $(df / | awk 'NR==2 {print $5}' | sed 's/%//') -gt 80 ]; then
    print_warning "Disk usage is high. Consider cleaning up or expanding storage."
fi

if ! systemctl is-active --quiet ufw; then
    print_warning "Firewall is not running. Consider enabling UFW for security."
fi

if ! systemctl is-active --quiet fail2ban; then
    print_warning "Fail2ban is not running. Consider enabling it for brute force protection."
fi

echo ""
echo "=========================================="
echo "           STATUS CHECK COMPLETE"
echo "=========================================="
echo ""