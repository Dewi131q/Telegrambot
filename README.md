# VPN Auto Installer Script

Auto install VPN server dengan tampilan menu interaktif berbasis Linux (Debian/Ubuntu). Script ini menyediakan manajemen lengkap untuk SSH, VLESS, VMess, dan Trojan.

## 🚀 Fitur Utama

- **Multi-Protocol Support**: SSH, VLESS, VMess, Trojan
- **Interactive Menu**: Tampilan menu yang user-friendly dengan warna
- **Account Management**: Create, list, delete, renew accounts
- **Auto Configuration**: Setup otomatis semua layanan
- **Domain Management**: Support custom domain dan IP
- **Banner Customization**: Custom banner untuk personalisasi
- **Port Checker**: Monitor status port dan konektivitas
- **System Monitoring**: Monitor RAM, CPU, disk usage
- **Service Management**: Control semua VPN services

## 📋 Persyaratan Sistem

- **OS**: Debian 10/11 atau Ubuntu 20.04+
- **RAM**: Minimal 512MB (Recommended 1GB+)
- **Storage**: Minimal 1GB free space
- **Network**: Public IP address
- **Access**: Root privileges

## 🛠️ Instalasi

### Instalasi Cepat

```bash
wget https://raw.githubusercontent.com/username/vpn-auto-installer/main/install.sh
chmod +x install.sh
./install.sh
```

### Manual Installation

```bash
# Clone repository
git clone https://github.com/username/vpn-auto-installer.git
cd vpn-auto-installer

# Run installer
chmod +x install.sh
./install.sh
```

## 📁 Struktur File

```
vpn-auto-installer/
├── install.sh          # Script installer utama
├── menu.sh             # Menu utama interface
├── utils.sh            # Fungsi utility sistem
├── ssh.sh              # Manajemen akun SSH
├── vless.sh            # Manajemen akun VLESS
├── vmess.sh            # Manajemen akun VMess
├── trojan.sh           # Manajemen akun Trojan
├── domain.sh           # Manajemen domain
├── banner.sh           # Manajemen banner
├── cekport.sh          # Port checker & monitor
├── config/             # Folder konfigurasi
│   ├── vless.json     # Config VLESS clients
│   ├── vmess.json     # Config VMess clients
│   └── trojan.json    # Config Trojan clients
├── akun/              # Folder data akun
│   ├── ssh/           # Data akun SSH
│   ├── vless/         # Data akun VLESS
│   ├── vmess/         # Data akun VMess
│   └── trojan/        # Data akun Trojan
└── log/               # Folder log aktivitas
```

## 🎯 Penggunaan

### Akses Menu Utama

Setelah instalasi selesai, akses menu dengan:

```bash
vpn-menu
```

atau

```bash
/usr/local/bin/vpn-script/menu.sh
```

### Menu Utama

```
========================================
              MAIN MENU
========================================
[1] SSH Account Manager
[2] VLESS Account Manager
[3] VMess Account Manager
[4] Trojan Account Manager
========================================
[5] Change Domain
[6] Change Banner
[7] Check Port Status
[8] Restart All Services
========================================
[0] Exit
```

## 📖 Panduan Penggunaan

### 1. SSH Account Management

#### Membuat Akun SSH
```bash
/usr/local/bin/vpn-script/ssh.sh create
```

**Input yang diperlukan:**
- Username
- Password (minimal 6 karakter)
- Masa aktif (hari)
- Batas koneksi simultan
- Kuota data (opsional)

**Output:**
- Informasi akun lengkap
- Payload WebSocket
- Config string

#### Mengelola Akun SSH
```bash
/usr/local/bin/vpn-script/ssh.sh list    # List semua akun
/usr/local/bin/vpn-script/ssh.sh delete  # Hapus akun
/usr/local/bin/vpn-script/ssh.sh renew   # Perpanjang akun
/usr/local/bin/vpn-script/ssh.sh check   # Cek login aktif
```

### 2. VLESS Account Management

#### Membuat Akun VLESS
```bash
/usr/local/bin/vpn-script/vless.sh create
```

**Output:**
- VLESS link siap pakai
- Manual config details
- QR code compatible

### 3. VMess Account Management

#### Membuat Akun VMess
```bash
/usr/local/bin/vpn-script/vmess.sh create
```

**Output:**
- VMess link (base64 encoded)
- Manual config details

### 4. Trojan Account Management

#### Membuat Akun Trojan
```bash
/usr/local/bin/vpn-script/trojan.sh create
```

**Output:**
- Trojan link siap pakai
- Manual config details

## 🌐 Domain Management

### Setting Custom Domain

```bash
/usr/local/bin/vpn-script/domain.sh
```

**Langkah-langkah:**
1. Buat A record di DNS provider
2. Point domain ke IP server
3. Tunggu propagasi DNS (5-60 menit)
4. Set domain melalui script

**DNS Setup Example:**
```
Type: A
Name: @ (root domain) atau vpn (subdomain)
Value: [Your Server IP]
TTL: 300
```

## 🎨 Banner Customization

### Mengubah Banner

```bash
/usr/local/bin/vpn-script/banner.sh
```

**Pilihan banner:**
- Custom text banner
- ASCII art banner
- Predefined banners
- Edit langsung file banner

## 🔍 Port & Service Monitoring

### Check Port Status

```bash
/usr/local/bin/vpn-script/cekport.sh
```

**Fitur monitoring:**
- Status semua port VPN
- Connectivity test
- Firewall status
- Network statistics
- Service status

## 📊 Default Ports

| Service | Port | Protocol | Description |
|---------|------|----------|-------------|
| SSH | 22 | TCP | OpenSSH |
| Dropbear | 143 | TCP | Dropbear SSH |
| HTTP | 80 | TCP | Nginx Web Server |
| HTTPS | 443 | TCP | Nginx SSL |
| VLESS | 8080 | TCP | VLESS WebSocket |
| VMess | 8443 | TCP | VMess WebSocket |
| Trojan | 2096 | TCP | Trojan WebSocket |
| WebSocket | 10000 | TCP | WebSocket Proxy |

## 🔧 Troubleshooting

### Common Issues

#### 1. Port tidak terbuka
```bash
# Cek firewall
iptables -L

# Cek service status
systemctl status xray
systemctl status nginx
systemctl status dropbear
```

#### 2. Domain tidak resolve
```bash
# Test DNS resolution
nslookup yourdomain.com
dig yourdomain.com

# Check domain script
/usr/local/bin/vpn-script/domain.sh check
```

#### 3. Service tidak jalan
```bash
# Restart semua service
/usr/local/bin/vpn-script/menu.sh
# Pilih option [8] Restart All Services

# Manual restart
systemctl restart xray nginx dropbear
```

### Log Files

- **Activity Log**: `/etc/vpn-script/log/activity.log`
- **Xray Log**: `journalctl -u xray`
- **Nginx Log**: `/var/log/nginx/error.log`

## 🔐 Security Features

- **Firewall Auto-Configuration**: Automatic iptables rules
- **User Isolation**: Proper user account separation
- **Access Control**: Connection limits per account
- **Expiry Management**: Automatic expired account cleanup
- **Activity Logging**: Comprehensive activity tracking

## 🚀 Performance Optimization

### Server Requirements by Usage

| Users | RAM | CPU | Bandwidth |
|-------|-----|-----|-----------|
| 1-10 | 512MB | 1 Core | 100GB/month |
| 10-50 | 1GB | 1 Core | 500GB/month |
| 50-100 | 2GB | 2 Core | 1TB/month |
| 100+ | 4GB+ | 2+ Core | 2TB+/month |

## 📝 Client Configuration

### SSH Client Config
```
Host: yourdomain.com
Port: 22 (OpenSSH) atau 143 (Dropbear)
Username: [created_username]
Password: [created_password]
```

### WebSocket Payload
```
GET / HTTP/1.1[crlf]Host: yourdomain.com[crlf]Upgrade: websocket[crlf][crlf]
```

### VLESS Client Config
```
Protocol: VLESS
Address: yourdomain.com
Port: 8080
UUID: [generated_uuid]
Network: WebSocket
Path: /vless
Security: None
```

### VMess Client Config
```
Protocol: VMess
Address: yourdomain.com
Port: 8443
UUID: [generated_uuid]
AlterID: 0
Network: WebSocket
Path: /vmess
Security: Auto
```

### Trojan Client Config
```
Protocol: Trojan
Address: yourdomain.com
Port: 2096
Password: [generated_password]
Network: WebSocket
Path: /trojan
Security: None
```

## 🔄 Update & Maintenance

### Manual Update
```bash
cd vpn-auto-installer
git pull origin main
chmod +x *.sh
```

### Backup Configuration
```bash
# Backup configs
tar -czf vpn-backup-$(date +%Y%m%d).tar.gz /etc/vpn-script/

# Restore from backup
tar -xzf vpn-backup-YYYYMMDD.tar.gz -C /
```

### Clean Expired Accounts
```bash
# Clean all expired accounts
/usr/local/bin/vpn-script/ssh.sh clean
/usr/local/bin/vpn-script/vless.sh clean
/usr/local/bin/vpn-script/vmess.sh clean
/usr/local/bin/vpn-script/trojan.sh clean
```

## 🤝 Contributing

1. Fork repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/username/vpn-auto-installer/issues)
- **Documentation**: [Wiki](https://github.com/username/vpn-auto-installer/wiki)
- **Telegram**: @vpn_installer_support

## ⭐ Credits

Created by VPN-Installer Team

**Powered by:**
- Xray-core
- Nginx
- Dropbear SSH
- Bash Scripting

---

## 📈 Changelog

### Version 1.0.0
- Initial release
- SSH, VLESS, VMess, Trojan support
- Interactive menu system
- Domain management
- Port monitoring
- Banner customization

---

**⚠️ Disclaimer**: Script ini dibuat untuk keperluan edukasi dan personal use. Pastikan penggunaan sesuai dengan hukum yang berlaku di negara Anda.