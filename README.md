# 🔰 Auto Install VPN Server Script

Script auto install VPN server lengkap berbasis Linux (Debian/Ubuntu) dengan tampilan menu interaktif di terminal.

## 📋 Fitur

- ✅ **Multi Protocol Support**: SSH, VLESS, VMess, Trojan
- ✅ **Interactive Menu**: Tampilan menu yang user-friendly
- ✅ **System Monitoring**: Info IP, RAM, Core, Domain
- ✅ **Service Status**: Monitoring status layanan aktif
- ✅ **Account Management**: Buat dan kelola akun VPN
- ✅ **Web Interface**: Dashboard web untuk melihat akun
- ✅ **Colorful Output**: Tampilan berwarna di terminal
- ✅ **Easy Setup**: Install otomatis dengan satu command

## 🛠️ Sistem Requirements

- **OS**: Debian 10/11 atau Ubuntu 20.04+
- **Architecture**: x86_64 / amd64
- **RAM**: Minimal 512MB
- **Storage**: Minimal 10GB
- **Root Access**: Diperlukan untuk instalasi

## 📁 Struktur Repository

```
vpn-script/
├── install.sh                 # Script utama untuk install
├── menu.sh                    # Menu utama interaktif
├── ssh.sh                     # Script buat akun SSH
├── vless.sh                   # Script buat akun VLESS
├── vmess.sh                   # Script buat akun VMess
├── trojan.sh                  # Script buat akun Trojan
├── domain.sh                  # Ganti domain
├── banner.sh                  # Ganti banner
├── cekport.sh                 # Cek port aktif
├── utils.sh                   # Fungsi utility
├── config/                    # Folder config JSON
├── akun/                      # Folder simpan akun
└── README.md                  # Dokumentasi
```

## 🚀 Cara Install

### 1. Download Script
```bash
wget -O install.sh https://raw.githubusercontent.com/username/vpn-script/main/install.sh
```

### 2. Jalankan Install
```bash
chmod +x install.sh
./install.sh
```

### 3. Akses Menu
```bash
vpn
```

## 📖 Cara Penggunaan

### Menu Utama
Setelah instalasi selesai, Anda akan melihat menu utama dengan opsi:

1. **Create SSH Account** - Buat akun SSH
2. **Create VLESS Account** - Buat akun VLESS
3. **Create VMess Account** - Buat akun VMess
4. **Create Trojan Account** - Buat akun Trojan
5. **Change Domain** - Ganti domain
6. **Change Banner** - Ganti banner
7. **Check Active Ports** - Cek port aktif
8. **Exit** - Keluar

### Buat Akun SSH
- Input: username, password, masa aktif, IP limit, kuota
- Output: Detail akun lengkap dengan payload websocket

### Buat Akun VLESS/VMess/Trojan
- Input: username, masa aktif
- Output: Link config dan detail akun

## 🌐 Web Interface

Setelah instalasi, Anda dapat mengakses dashboard web di:
- **URL**: `http://YOUR_IP/`
- **Account Files**: `http://YOUR_IP/akun/`

## 🔧 Konfigurasi

### Domain
- File: `/etc/xray/domain`
- Ganti melalui menu atau edit manual

### Banner
- File: `/etc/issue.net`
- Ganti melalui menu atau edit manual

### Services
- **Dropbear**: Port 22
- **Nginx**: Port 80
- **XRAY**: Port 443

## 📊 Monitoring

Script menampilkan informasi sistem:
- **IP VPS**: IP publik server
- **RAM**: Kapasitas RAM
- **CPU Core**: Jumlah core CPU
- **Domain**: Domain yang digunakan
- **Service Status**: Status layanan aktif

## 🛡️ Security

- Semua password di-hash dengan aman
- UUID otomatis untuk VLESS/VMess
- Password random untuk Trojan
- File akun tersimpan di folder terpisah

## 🔄 Update

Untuk update script:
```bash
wget -O install.sh https://raw.githubusercontent.com/username/vpn-script/main/install.sh
chmod +x install.sh
./install.sh
```

## 🐛 Troubleshooting

### Error "Permission Denied"
```bash
chmod +x install.sh
```

### Error "Command Not Found"
```bash
apt update && apt install -y curl wget
```

### Service Tidak Berjalan
```bash
systemctl status nginx
systemctl status dropbear
systemctl status xray
```

## 📝 Log Files

- **Nginx**: `/var/log/nginx/`
- **XRAY**: `/var/log/xray/`
- **System**: `/var/log/syslog`

## 🤝 Contributing

1. Fork repository
2. Buat branch baru (`git checkout -b feature/AmazingFeature`)
3. Commit perubahan (`git commit -m 'Add some AmazingFeature'`)
4. Push ke branch (`git push origin feature/AmazingFeature`)
5. Buat Pull Request

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

## 👨‍💻 Author

**VPN Script Creator**
- GitHub: [@username](https://github.com/username)

## 🙏 Acknowledgments

- XRAY Project
- Nginx Team
- Debian/Ubuntu Community

## 📞 Support

Jika ada pertanyaan atau masalah:
- Buat issue di GitHub
- Email: support@example.com
- Telegram: @vpnscript

---

**⚠️ Disclaimer**: Script ini dibuat untuk tujuan edukasi dan pengembangan. Pengguna bertanggung jawab penuh atas penggunaan script ini.