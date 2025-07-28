#!/bin/bash

# VPN Script Main Menu
# Created by VPN-Installer

# Source utility functions
source /usr/local/bin/vpn-script/utils.sh

# Check if running as root
check_root

# Main menu function
show_main_menu() {
    print_complete_status
    
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}              MAIN MENU${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "${YELLOW}[1]${NC} SSH Account Manager"
    echo -e "${YELLOW}[2]${NC} VLESS Account Manager"
    echo -e "${YELLOW}[3]${NC} VMess Account Manager"
    echo -e "${YELLOW}[4]${NC} Trojan Account Manager"
    echo -e "${CYAN}========================================${NC}"
    echo -e "${YELLOW}[5]${NC} Change Domain"
    echo -e "${YELLOW}[6]${NC} Change Banner"
    echo -e "${YELLOW}[7]${NC} Check Port Status"
    echo -e "${YELLOW}[8]${NC} Restart All Services"
    echo -e "${CYAN}========================================${NC}"
    echo -e "${YELLOW}[0]${NC} Exit"
    echo -e "${CYAN}========================================${NC}"
    echo ""
}

# SSH submenu
show_ssh_menu() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}         SSH ACCOUNT MANAGER${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "${YELLOW}[1]${NC} Create SSH Account"
    echo -e "${YELLOW}[2]${NC} List SSH Accounts"
    echo -e "${YELLOW}[3]${NC} Delete SSH Account"
    echo -e "${YELLOW}[4]${NC} Renew SSH Account"
    echo -e "${YELLOW}[5]${NC} Check SSH Login"
    echo -e "${CYAN}========================================${NC}"
    echo -e "${YELLOW}[0]${NC} Back to Main Menu"
    echo -e "${CYAN}========================================${NC}"
    echo ""
}

# VLESS submenu
show_vless_menu() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}        VLESS ACCOUNT MANAGER${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "${YELLOW}[1]${NC} Create VLESS Account"
    echo -e "${YELLOW}[2]${NC} List VLESS Accounts"
    echo -e "${YELLOW}[3]${NC} Delete VLESS Account"
    echo -e "${YELLOW}[4]${NC} Renew VLESS Account"
    echo -e "${CYAN}========================================${NC}"
    echo -e "${YELLOW}[0]${NC} Back to Main Menu"
    echo -e "${CYAN}========================================${NC}"
    echo ""
}

# VMess submenu
show_vmess_menu() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}        VMESS ACCOUNT MANAGER${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "${YELLOW}[1]${NC} Create VMess Account"
    echo -e "${YELLOW}[2]${NC} List VMess Accounts"
    echo -e "${YELLOW}[3]${NC} Delete VMess Account"
    echo -e "${YELLOW}[4]${NC} Renew VMess Account"
    echo -e "${CYAN}========================================${NC}"
    echo -e "${YELLOW}[0]${NC} Back to Main Menu"
    echo -e "${CYAN}========================================${NC}"
    echo ""
}

# Trojan submenu
show_trojan_menu() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}       TROJAN ACCOUNT MANAGER${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "${YELLOW}[1]${NC} Create Trojan Account"
    echo -e "${YELLOW}[2]${NC} List Trojan Accounts"
    echo -e "${YELLOW}[3]${NC} Delete Trojan Account"
    echo -e "${YELLOW}[4]${NC} Renew Trojan Account"
    echo -e "${CYAN}========================================${NC}"
    echo -e "${YELLOW}[0]${NC} Back to Main Menu"
    echo -e "${CYAN}========================================${NC}"
    echo ""
}

# Handle SSH menu selection
handle_ssh_menu() {
    while true; do
        show_ssh_menu
        read -p "Pilih menu [0-5]: " ssh_choice
        
        case $ssh_choice in
            1)
                /usr/local/bin/vpn-script/ssh.sh create
                read -p "Tekan Enter untuk kembali ke menu..."
                ;;
            2)
                /usr/local/bin/vpn-script/ssh.sh list
                read -p "Tekan Enter untuk kembali ke menu..."
                ;;
            3)
                /usr/local/bin/vpn-script/ssh.sh delete
                read -p "Tekan Enter untuk kembali ke menu..."
                ;;
            4)
                /usr/local/bin/vpn-script/ssh.sh renew
                read -p "Tekan Enter untuk kembali ke menu..."
                ;;
            5)
                /usr/local/bin/vpn-script/ssh.sh check
                read -p "Tekan Enter untuk kembali ke menu..."
                ;;
            0)
                break
                ;;
            *)
                echo -e "${RED}[ERROR]${NC} Pilihan tidak valid!"
                sleep 2
                ;;
        esac
    done
}

# Handle VLESS menu selection
handle_vless_menu() {
    while true; do
        show_vless_menu
        read -p "Pilih menu [0-4]: " vless_choice
        
        case $vless_choice in
            1)
                /usr/local/bin/vpn-script/vless.sh create
                read -p "Tekan Enter untuk kembali ke menu..."
                ;;
            2)
                /usr/local/bin/vpn-script/vless.sh list
                read -p "Tekan Enter untuk kembali ke menu..."
                ;;
            3)
                /usr/local/bin/vpn-script/vless.sh delete
                read -p "Tekan Enter untuk kembali ke menu..."
                ;;
            4)
                /usr/local/bin/vpn-script/vless.sh renew
                read -p "Tekan Enter untuk kembali ke menu..."
                ;;
            0)
                break
                ;;
            *)
                echo -e "${RED}[ERROR]${NC} Pilihan tidak valid!"
                sleep 2
                ;;
        esac
    done
}

# Handle VMess menu selection
handle_vmess_menu() {
    while true; do
        show_vmess_menu
        read -p "Pilih menu [0-4]: " vmess_choice
        
        case $vmess_choice in
            1)
                /usr/local/bin/vpn-script/vmess.sh create
                read -p "Tekan Enter untuk kembali ke menu..."
                ;;
            2)
                /usr/local/bin/vpn-script/vmess.sh list
                read -p "Tekan Enter untuk kembali ke menu..."
                ;;
            3)
                /usr/local/bin/vpn-script/vmess.sh delete
                read -p "Tekan Enter untuk kembali ke menu..."
                ;;
            4)
                /usr/local/bin/vpn-script/vmess.sh renew
                read -p "Tekan Enter untuk kembali ke menu..."
                ;;
            0)
                break
                ;;
            *)
                echo -e "${RED}[ERROR]${NC} Pilihan tidak valid!"
                sleep 2
                ;;
        esac
    done
}

# Handle Trojan menu selection
handle_trojan_menu() {
    while true; do
        show_trojan_menu
        read -p "Pilih menu [0-4]: " trojan_choice
        
        case $trojan_choice in
            1)
                /usr/local/bin/vpn-script/trojan.sh create
                read -p "Tekan Enter untuk kembali ke menu..."
                ;;
            2)
                /usr/local/bin/vpn-script/trojan.sh list
                read -p "Tekan Enter untuk kembali ke menu..."
                ;;
            3)
                /usr/local/bin/vpn-script/trojan.sh delete
                read -p "Tekan Enter untuk kembali ke menu..."
                ;;
            4)
                /usr/local/bin/vpn-script/trojan.sh renew
                read -p "Tekan Enter untuk kembali ke menu..."
                ;;
            0)
                break
                ;;
            *)
                echo -e "${RED}[ERROR]${NC} Pilihan tidak valid!"
                sleep 2
                ;;
        esac
    done
}

# Main program loop
main() {
    while true; do
        show_main_menu
        read -p "Pilih menu [0-8]: " choice
        
        case $choice in
            1)
                handle_ssh_menu
                ;;
            2)
                handle_vless_menu
                ;;
            3)
                handle_vmess_menu
                ;;
            4)
                handle_trojan_menu
                ;;
            5)
                /usr/local/bin/vpn-script/domain.sh
                read -p "Tekan Enter untuk kembali ke menu..."
                ;;
            6)
                /usr/local/bin/vpn-script/banner.sh
                read -p "Tekan Enter untuk kembali ke menu..."
                ;;
            7)
                /usr/local/bin/vpn-script/cekport.sh
                read -p "Tekan Enter untuk kembali ke menu..."
                ;;
            8)
                echo -e "${YELLOW}[INFO]${NC} Restarting all services..."
                restart_services
                read -p "Tekan Enter untuk kembali ke menu..."
                ;;
            0)
                clear
                echo -e "${GREEN}Terima kasih telah menggunakan VPN Script!${NC}"
                echo -e "${CYAN}Created by VPN-Installer${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}[ERROR]${NC} Pilihan tidak valid!"
                sleep 2
                ;;
        esac
    done
}

# Run main program
main