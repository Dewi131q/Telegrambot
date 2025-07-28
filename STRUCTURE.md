# Repository Structure

```
vpn-script/
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md
│   │   └── feature_request.md
│   ├── workflows/
│   │   └── ci.yml
│   └── pull_request_template.md
├── config/                    # Folder untuk config JSON
├── akun/                      # Folder untuk simpan akun
├── docs/
│   ├── API.md
│   ├── INSTALLATION.md
│   └── USAGE.md
├── scripts/
│   ├── backup.sh
│   ├── monitor.sh
│   └── uninstall.sh
├── tests/
│   └── test_install.sh
├── .gitignore
├── CHANGELOG.md
├── CODE_OF_CONDUCT.md
├── CONTRIBUTING.md
├── install.sh                 # Script utama untuk install
├── LICENSE
├── README.md
├── SECURITY.md
└── STRUCTURE.md
```

## File Descriptions

### Main Scripts
- **`install.sh`** - Script utama untuk instalasi VPN server
- **`scripts/backup.sh`** - Script backup dan restore
- **`scripts/monitor.sh`** - Script monitoring sistem
- **`scripts/uninstall.sh`** - Script uninstall VPN server

### Documentation
- **`README.md`** - Dokumentasi utama repository
- **`docs/API.md`** - Dokumentasi API functions
- **`docs/INSTALLATION.md`** - Panduan instalasi lengkap
- **`docs/USAGE.md`** - Panduan penggunaan lengkap
- **`CHANGELOG.md`** - Riwayat perubahan versi
- **`CONTRIBUTING.md`** - Panduan kontribusi
- **`CODE_OF_CONDUCT.md`** - Kode etik komunitas
- **`SECURITY.md`** - Kebijakan keamanan

### Testing
- **`tests/test_install.sh`** - Script testing instalasi

### GitHub Templates
- **`.github/ISSUE_TEMPLATE/bug_report.md`** - Template bug report
- **`.github/ISSUE_TEMPLATE/feature_request.md`** - Template feature request
- **`.github/pull_request_template.md`** - Template pull request
- **`.github/workflows/ci.yml`** - GitHub Actions CI/CD

### Configuration
- **`.gitignore`** - File yang diabaikan Git
- **`LICENSE`** - Lisensi MIT
- **`STRUCTURE.md`** - File ini (struktur repository)

### Directories
- **`config/`** - Folder untuk menyimpan config JSON
- **`akun/`** - Folder untuk menyimpan file akun
- **`docs/`** - Folder dokumentasi
- **`scripts/`** - Folder script tambahan
- **`tests/`** - Folder testing

## Installation Structure

Setelah instalasi, script akan membuat struktur berikut di sistem:

```
/usr/local/bin/vpn/
├── menu.sh                    # Menu utama
├── utils.sh                   # Fungsi utility
├── ssh.sh                     # Script buat akun SSH
├── vless.sh                   # Script buat akun VLESS
├── vmess.sh                   # Script buat akun VMess
├── trojan.sh                  # Script buat akun Trojan
├── domain.sh                  # Script ganti domain
├── banner.sh                  # Script ganti banner
└── cekport.sh                 # Script cek port

/etc/xray/
└── domain                     # File konfigurasi domain

/home/vps/public_html/
├── index.html                 # Web interface
└── akun/                      # Folder akun (web accessible)

/backup/vpn/                   # Folder backup (opsional)
```

## Features Overview

### Core Features
- ✅ Multi-protocol VPN (SSH, VLESS, VMess, Trojan)
- ✅ Interactive menu system
- ✅ System monitoring
- ✅ Web interface
- ✅ Backup and restore
- ✅ Comprehensive documentation

### Security Features
- ✅ Password hashing
- ✅ Input validation
- ✅ Service isolation
- ✅ Error handling
- ✅ Log monitoring

### Management Features
- ✅ Account creation
- ✅ Domain management
- ✅ Banner customization
- ✅ Port monitoring
- ✅ Service status checking

### Documentation Features
- ✅ Comprehensive README
- ✅ Installation guide
- ✅ Usage guide
- ✅ API documentation
- ✅ Contributing guidelines
- ✅ Security policy