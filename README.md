# VPS Auto Install Scripts untuk Ubuntu 20.04

Script-script ini akan membantu Anda menginstall dan mengkonfigurasi VPS Ubuntu 20.04 secara otomatis dengan berbagai komponen yang diperlukan untuk hosting website.

## 📋 Daftar Script

1. **`vps_auto_install.sh`** - Script utama untuk setup VPS
2. **`install_wordpress.sh`** - Script untuk install WordPress
3. **`install_laravel.sh`** - Script untuk install Laravel

## 🚀 Cara Penggunaan

### 1. Setup VPS Dasar

```bash
# Download script
wget https://raw.githubusercontent.com/your-repo/vps_auto_install.sh

# Berikan permission execute
chmod +x vps_auto_install.sh

# Jalankan script sebagai root
sudo ./vps_auto_install.sh
```

### 2. Install WordPress (Opsional)

```bash
# Download script WordPress
wget https://raw.githubusercontent.com/your-repo/install_wordpress.sh

# Berikan permission execute
chmod +x install_wordpress.sh

# Jalankan script
sudo ./install_wordpress.sh
```

### 3. Install Laravel (Opsional)

```bash
# Download script Laravel
wget https://raw.githubusercontent.com/your-repo/install_laravel.sh

# Berikan permission execute
chmod +x install_laravel.sh

# Jalankan script
sudo ./install_laravel.sh
```

## 📦 Komponen yang Diinstall

### Sistem Dasar
- ✅ Update sistem Ubuntu 20.04
- ✅ Paket-paket penting (curl, wget, git, dll)
- ✅ UFW Firewall dengan konfigurasi keamanan
- ✅ Fail2ban untuk proteksi brute force
- ✅ SSH dengan konfigurasi keamanan

### Web Server
- ✅ Nginx web server
- ✅ PHP 8.1 dengan ekstensi lengkap
- ✅ MariaDB database server
- ✅ Certbot untuk SSL certificate

### Development Tools
- ✅ Node.js 18.x dan npm
- ✅ PM2 untuk process management
- ✅ Composer untuk PHP package manager

### Monitoring & Backup
- ✅ Script monitoring sistem
- ✅ Script backup otomatis
- ✅ Cron job untuk backup harian

## 🔧 Konfigurasi Keamanan

### Firewall (UFW)
- Port 22 (SSH) - Terbuka
- Port 80 (HTTP) - Terbuka
- Port 443 (HTTPS) - Terbuka
- Semua port lain - Tertutup

### SSH Security
- Root login dinonaktifkan
- Password authentication diaktifkan
- Key-based authentication diaktifkan
- Login grace time: 120 detik

### Database Security
- MariaDB dengan konfigurasi aman
- User database terpisah untuk setiap aplikasi
- Password yang di-generate secara random

## 📊 Monitoring

### Script Monitoring
```bash
# Jalankan monitoring sistem
system-monitor.sh
```

Output akan menampilkan:
- Uptime server
- Penggunaan memory
- Penggunaan disk
- Load CPU
- Jumlah koneksi aktif

### Backup Otomatis
```bash
# Backup manual
backup-sites.sh
```

Backup akan menyimpan:
- File website di `/backup/websites_YYYYMMDD_HHMMSS.tar.gz`
- Database di `/backup/databases_YYYYMMDD_HHMMSS.sql`
- Backup otomatis setiap hari jam 2 pagi
- Menyimpan backup 7 hari terakhir

## 🌐 Web Applications

### WordPress
- ✅ Download WordPress terbaru
- ✅ Konfigurasi database otomatis
- ✅ Konfigurasi Nginx untuk WordPress
- ✅ File wp-config.php otomatis dibuat
- ✅ Permission file yang benar

### Laravel
- ✅ Install Laravel via Composer
- ✅ Konfigurasi database otomatis
- ✅ Konfigurasi Nginx untuk Laravel
- ✅ Environment file (.env) otomatis
- ✅ Optimasi cache dan autoloader

## 🔐 SSL Certificate

Setelah install website, Anda bisa menambahkan SSL certificate:

```bash
# Install SSL untuk domain
certbot --nginx -d yourdomain.com

# Auto-renewal sudah dikonfigurasi otomatis
```

## 📝 Perintah Berguna

### Restart Services
```bash
# Restart Nginx
systemctl restart nginx

# Restart PHP-FPM
systemctl restart php8.1-fpm

# Restart MariaDB
systemctl restart mariadb

# Restart SSH
systemctl restart ssh
```

### Check Status Services
```bash
# Check status semua service
systemctl status nginx php8.1-fpm mariadb ssh ufw fail2ban

# Check firewall rules
ufw status

# Check fail2ban status
fail2ban-client status
```

### Database Management
```bash
# Masuk ke MySQL
mysql -u root -p

# Backup database
mysqldump -u root -p --all-databases > backup.sql

# Restore database
mysql -u root -p < backup.sql
```

## ⚠️ Penting untuk Diperhatikan

1. **Password Database**: Simpan password database yang di-generate
2. **SSL Certificate**: Install SSL setelah website siap
3. **File info.php**: Hapus file info.php setelah selesai setup
4. **Firewall**: Sesuaikan firewall sesuai kebutuhan aplikasi
5. **Backup**: Pastikan backup berjalan dengan baik
6. **Monitoring**: Periksa monitoring secara berkala

## 🆘 Troubleshooting

### Nginx Error
```bash
# Check Nginx configuration
nginx -t

# Check Nginx error log
tail -f /var/log/nginx/error.log
```

### PHP Error
```bash
# Check PHP-FPM status
systemctl status php8.1-fpm

# Check PHP error log
tail -f /var/log/php8.1-fpm.log
```

### Database Error
```bash
# Check MariaDB status
systemctl status mariadb

# Check MariaDB error log
tail -f /var/log/mysql/error.log
```

## 📞 Support

Jika ada masalah atau pertanyaan:
1. Periksa log file di `/var/log/`
2. Jalankan script monitoring untuk diagnose
3. Pastikan semua service berjalan dengan baik

## 🔄 Update Script

Untuk update script ke versi terbaru:
```bash
# Download script terbaru
wget https://raw.githubusercontent.com/your-repo/vps_auto_install.sh -O vps_auto_install.sh.new

# Backup script lama
cp vps_auto_install.sh vps_auto_install.sh.backup

# Ganti dengan script baru
mv vps_auto_install.sh.new vps_auto_install.sh
chmod +x vps_auto_install.sh
```

---

**Note**: Script ini dibuat untuk Ubuntu 20.04. Untuk versi Ubuntu lain, mungkin perlu penyesuaian.