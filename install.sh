#!/usr/bin/env bash
#=============================================================
# Auto Install VPN Script (install.sh)
# Supports: Debian 10/11 & Ubuntu 20.04
# Author  : YOUR_NAME
# Github  : https://github.com/YOUR_REPO
#=============================================================

#---------------------- CONFIGURATION ------------------------
REPO_RAW="https://raw.githubusercontent.com/YOUR_REPO/main"  # <-- ganti dengan repo asli
SCRIPT_LIST=(menu.sh ssh.sh vless.sh vmess.sh trojan.sh domain.sh banner.sh cekport.sh utils.sh)
INSTALL_DIR="/usr/local/sbin"   # lokasi instalasi script bin
DATA_DIR="/etc/vpn"            # lokasi penyimpanan data akun & config
CONFIG_DIR="$DATA_DIR/config"  # tempat file JSON config
AKUN_DIR="$DATA_DIR/akun"      # tempat data akun user

#---------------------- WARNA TERMINAL -----------------------
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
NC='\e[0m' # No Color

#---------------------- UTILITY FUNGS ------------------------
msg_info(){ echo -e "${BLUE}[INFO]${NC} $1"; }
msg_ok(){   echo -e "${GREEN}[OK]${NC}   $1"; }
msg_err(){  echo -e "${RED}[ERROR]${NC} $1"; }

require_root(){
    if [[ $EUID -ne 0 ]]; then
        msg_err "Jalankan script ini sebagai root! (sudo -i)"
        exit 1
    fi
}

check_os(){
    . /etc/os-release
    case "$ID" in
        debian)
            if [[ $VERSION_ID != "10" && $VERSION_ID != "11" ]]; then
                msg_err "Debian $VERSION_ID tidak didukung. Gunakan Debian 10/11."
                exit 1
            fi
            ;;
        ubuntu)
            if [[ $VERSION_ID != "20.04" ]]; then
                msg_err "Ubuntu $VERSION_ID tidak didukung. Gunakan Ubuntu 20.04."
                exit 1
            fi
            ;;
        *)
            msg_err "OS $ID tidak didukung. Hanya Debian 10/11 & Ubuntu 20.04."
            exit 1
            ;;
    esac
    msg_ok "OS kompatibel: $PRETTY_NAME"
}

install_deps(){
    msg_info "Memperbarui repositori & menginstal dependensi ..."
    apt-get update -y && \
    apt-get install -y --no-install-recommends \
        curl wget gnupg lsb-release jq tar gzip unzip net-tools bc dropbear nginx
    msg_ok "Dependensi terinstal."
}

install_xray(){
    if command -v xray >/dev/null 2>&1; then
        msg_ok "Xray sudah terinstal. Melewati ..."
        return
    fi
    msg_info "Mengunduh & memasang Xray Core ..."
    XRAY_VER=$(curl -s "https://api.github.com/repos/XTLS/Xray-core/releases/latest" | jq -r '.tag_name')
    ARCH=$(uname -m)
    case $ARCH in
        x86_64) ARCH="64";;
        aarch64) ARCH="arm64-v8a";;
        *) msg_err "Arsitektur $ARCH tidak didukung oleh skrip otomatis ini."; exit 1;;
    esac
    wget -qO- "https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-$ARCH.tar.xz" | tar -xJf - -C /usr/local/bin xray && \
    chmod +x /usr/local/bin/xray
    msg_ok "Xray $XRAY_VER terinstal."

    # Setup systemd service jika belum ada
    if [[ ! -f /etc/systemd/system/xray.service ]]; then
        cat <<-SERVICE >/etc/systemd/system/xray.service
[Unit]
Description=Xray Service
After=network.target nss-lookup.target

[Service]
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray run -config $CONFIG_DIR/config.json
Restart=on-failure

[Install]
WantedBy=multi-user.target
SERVICE
        systemctl daemon-reload
        systemctl enable xray
    fi
}

download_scripts(){
    msg_info "Mengunduh script tambahan ..."
    mkdir -p "$INSTALL_DIR" "$CONFIG_DIR" "$AKUN_DIR"
    for script in "${SCRIPT_LIST[@]}"; do
        url="$REPO_RAW/$script"
        dest="$INSTALL_DIR/${script%%.sh}"
        wget -qO "$dest" "$url" || { msg_err "Gagal mengunduh $script"; exit 1; }
        chmod +x "$dest"
        ln -sf "$dest" "/usr/bin/${script%%.sh}"  # alias nama pendek
    done
    msg_ok "Semua script terunduh dan siap digunakan."
}

show_sysinfo(){
    IP="$(curl -s ipv4.icanhazip.com)"
    MEM_TOTAL="$(free -m | awk '/Mem:/ {print $2" MB"}')"
    CORES="$(nproc)"
    DOMAIN="$(cat $DATA_DIR/domain 2>/dev/null || echo "- belum diatur -")"

    echo -e "\n${YELLOW}=========================================${NC}"
    echo -e "   IP VPS    : $IP"
    echo -e "   RAM       : $MEM_TOTAL"
    echo -e "   CPU Cores : $CORES"
    echo -e "   Domain    : $DOMAIN"
    echo -e "   Creator   : YOUR_NAME"
    echo -e "${YELLOW}=========================================${NC}\n"
}

main(){
    require_root
    show_sysinfo
    check_os
    install_deps
    install_xray
    download_scripts
    systemctl restart nginx dropbear xray 2>/dev/null || true
    msg_ok "Instalasi selesai! Ketik ${GREEN}menu${NC} untuk mulai menggunakan panel."
}

main "$@"