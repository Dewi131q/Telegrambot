#!/bin/bash

# Banner Manager
# Created by VPN-Installer

# Source utility functions
source /usr/local/bin/vpn-script/utils.sh

# Check if running as root
check_root

# Banner configuration file
BANNER_FILE="/etc/vpn-script/banner.txt"

# Show current banner
show_current_banner() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}         CURRENT BANNER${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    
    if [[ -f "$BANNER_FILE" ]]; then
        echo -e "${PURPLE}"
        cat "$BANNER_FILE"
        echo -e "${NC}"
    else
        echo -e "${PURPLE}VPN Server${NC}"
        echo -e "${YELLOW}[INFO]${NC} Using default banner"
    fi
    
    echo ""
    echo -e "${CYAN}========================================${NC}"
}

# Change banner
change_banner() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}           CHANGE BANNER${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    
    echo -e "${YELLOW}Options:${NC}"
    echo -e "[1] Custom text banner"
    echo -e "[2] ASCII art banner"
    echo -e "[3] Predefined banners"
    echo -e "[4] Remove banner (use default)"
    echo -e "[0] Cancel"
    echo ""
    
    read -p "Choose option [0-4]: " choice
    
    case $choice in
        1)
            create_custom_banner
            ;;
        2)
            create_ascii_banner
            ;;
        3)
            choose_predefined_banner
            ;;
        4)
            remove_banner
            ;;
        0)
            echo -e "${YELLOW}[INFO]${NC} Operation cancelled."
            return
            ;;
        *)
            echo -e "${RED}[ERROR]${NC} Invalid option!"
            sleep 2
            change_banner
            ;;
    esac
}

# Create custom text banner
create_custom_banner() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}         CUSTOM TEXT BANNER${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    
    echo -e "${YELLOW}Enter your custom banner text:${NC}"
    echo -e "${YELLOW}(Press Enter on empty line to finish)${NC}"
    echo ""
    
    # Read multi-line input
    local banner_text=""
    local line
    
    while true; do
        read -r line
        if [[ -z "$line" ]]; then
            break
        fi
        banner_text="${banner_text}${line}\n"
    done
    
    if [[ -z "$banner_text" ]]; then
        echo -e "${YELLOW}[INFO]${NC} No banner text entered. Operation cancelled."
        return
    fi
    
    # Remove trailing newline
    banner_text=$(echo -e "$banner_text" | head -c -1)
    
    # Preview banner
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}           BANNER PREVIEW${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    echo -e "${PURPLE}$banner_text${NC}"
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo ""
    
    read -p "Save this banner? (yes/no): " confirm
    
    if [[ "$confirm" == "yes" ]]; then
        echo -e "$banner_text" > "$BANNER_FILE"
        echo -e "${GREEN}[SUCCESS]${NC} Custom banner saved!"
        log_activity "Custom banner created"
    else
        echo -e "${YELLOW}[INFO]${NC} Banner not saved."
    fi
}

# Create ASCII art banner
create_ascii_banner() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}         ASCII ART BANNER${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    
    echo -e "${YELLOW}Enter text to convert to ASCII art:${NC}"
    read -p "Text: " input_text
    
    if [[ -z "$input_text" ]]; then
        echo -e "${RED}[ERROR]${NC} No text entered!"
        return
    fi
    
    # Check if figlet is available
    if ! command -v figlet >/dev/null; then
        echo -e "${YELLOW}[INFO]${NC} Installing figlet for ASCII art..."
        apt update && apt install -y figlet
    fi
    
    if command -v figlet >/dev/null; then
        # Generate ASCII art
        local ascii_art=$(figlet -f standard "$input_text")
        
        # Preview banner
        echo ""
        echo -e "${CYAN}========================================${NC}"
        echo -e "${GREEN}           BANNER PREVIEW${NC}"
        echo -e "${CYAN}========================================${NC}"
        echo ""
        echo -e "${PURPLE}$ascii_art${NC}"
        echo ""
        echo -e "${CYAN}========================================${NC}"
        echo ""
        
        read -p "Save this ASCII banner? (yes/no): " confirm
        
        if [[ "$confirm" == "yes" ]]; then
            echo "$ascii_art" > "$BANNER_FILE"
            echo -e "${GREEN}[SUCCESS]${NC} ASCII banner saved!"
            log_activity "ASCII banner created: $input_text"
        else
            echo -e "${YELLOW}[INFO]${NC} Banner not saved."
        fi
    else
        echo -e "${RED}[ERROR]${NC} Failed to install figlet. Cannot create ASCII art."
    fi
}

# Choose predefined banner
choose_predefined_banner() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}        PREDEFINED BANNERS${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    
    echo -e "${YELLOW}Choose a predefined banner:${NC}"
    echo ""
    echo -e "[1] VPN Server"
    echo -e "[2] Welcome to VPN"
    echo -e "[3] Secure Connection"
    echo -e "[4] Private Network"
    echo -e "[5] Enterprise VPN"
    echo -e "[0] Cancel"
    echo ""
    
    read -p "Choose banner [0-5]: " choice
    
    local banner_text=""
    
    case $choice in
        1)
            banner_text="VPN Server
═══════════════════════════════════════
      Professional VPN Solution"
            ;;
        2)
            banner_text="╔══════════════════════════════════════╗
║           Welcome to VPN             ║
║      Your Gateway to Privacy        ║
╚══════════════════════════════════════╝"
            ;;
        3)
            banner_text="🔒 SECURE CONNECTION 🔒
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
    Protecting Your Digital Life"
            ;;
        4)
            banner_text="┌─────────────────────────────────────┐
│          PRIVATE NETWORK            │
│     Fast • Secure • Anonymous       │
└─────────────────────────────────────┘"
            ;;
        5)
            banner_text="ENTERPRISE VPN SOLUTION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Business Grade Security & Performance
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            ;;
        0)
            echo -e "${YELLOW}[INFO]${NC} Operation cancelled."
            return
            ;;
        *)
            echo -e "${RED}[ERROR]${NC} Invalid option!"
            sleep 2
            choose_predefined_banner
            return
            ;;
    esac
    
    # Preview banner
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}           BANNER PREVIEW${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    echo -e "${PURPLE}$banner_text${NC}"
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo ""
    
    read -p "Use this banner? (yes/no): " confirm
    
    if [[ "$confirm" == "yes" ]]; then
        echo -e "$banner_text" > "$BANNER_FILE"
        echo -e "${GREEN}[SUCCESS]${NC} Predefined banner saved!"
        log_activity "Predefined banner #$choice selected"
    else
        echo -e "${YELLOW}[INFO]${NC} Banner not saved."
    fi
}

# Remove banner
remove_banner() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}          REMOVE BANNER${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    
    if [[ -f "$BANNER_FILE" ]]; then
        echo -e "${YELLOW}Current banner will be removed.${NC}"
        echo -e "${YELLOW}Default banner will be used instead.${NC}"
        echo ""
        
        read -p "Are you sure? (yes/no): " confirm
        
        if [[ "$confirm" == "yes" ]]; then
            rm -f "$BANNER_FILE"
            echo -e "${GREEN}[SUCCESS]${NC} Banner removed! Using default banner."
            log_activity "Banner removed"
        else
            echo -e "${YELLOW}[INFO]${NC} Operation cancelled."
        fi
    else
        echo -e "${YELLOW}[INFO]${NC} No custom banner found. Already using default banner."
    fi
}

# Preview banner
preview_banner() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}          BANNER PREVIEW${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    
    echo -e "${YELLOW}This is how the banner appears in the main menu:${NC}"
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${PURPLE}$(get_banner)${NC}"
    echo ""
    print_system_info
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}              MAIN MENU${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "${YELLOW}[1]${NC} SSH Account Manager"
    echo -e "${YELLOW}[2]${NC} VLESS Account Manager"
    echo -e "${YELLOW}[3]${NC} VMess Account Manager"
    echo -e "${YELLOW}[4]${NC} Trojan Account Manager"
    echo -e "${CYAN}========================================${NC}"
    echo ""
}

# Edit banner file directly
edit_banner_file() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}         EDIT BANNER FILE${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    
    if command -v nano >/dev/null; then
        echo -e "${YELLOW}Opening banner file in nano editor...${NC}"
        echo -e "${YELLOW}Press Ctrl+X to save and exit${NC}"
        sleep 2
        
        # Create file if not exists
        touch "$BANNER_FILE"
        
        # Edit file
        nano "$BANNER_FILE"
        
        echo -e "${GREEN}[SUCCESS]${NC} Banner file edited!"
        log_activity "Banner file edited directly"
    else
        echo -e "${RED}[ERROR]${NC} Nano editor not found!"
        echo -e "${YELLOW}[INFO]${NC} Installing nano..."
        apt update && apt install -y nano
        
        if command -v nano >/dev/null; then
            edit_banner_file
        else
            echo -e "${RED}[ERROR]${NC} Failed to install nano editor!"
        fi
    fi
}

# Main menu
main_menu() {
    while true; do
        show_current_banner
        echo ""
        echo -e "${YELLOW}Options:${NC}"
        echo -e "[1] Change Banner"
        echo -e "[2] Preview Banner"
        echo -e "[3] Edit Banner File"
        echo -e "[4] Remove Banner"
        echo -e "[0] Back to Main Menu"
        echo ""
        
        read -p "Choose option [0-4]: " choice
        
        case $choice in
            1)
                change_banner
                read -p "Press Enter to continue..."
                ;;
            2)
                preview_banner
                read -p "Press Enter to continue..."
                ;;
            3)
                edit_banner_file
                read -p "Press Enter to continue..."
                ;;
            4)
                remove_banner
                read -p "Press Enter to continue..."
                ;;
            0)
                break
                ;;
            *)
                echo -e "${RED}[ERROR]${NC} Invalid option!"
                sleep 2
                ;;
        esac
    done
}

# Show banner info
show_banner_info() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}         BANNER INFORMATION${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    
    if [[ -f "$BANNER_FILE" ]]; then
        echo -e "Banner file   : ${GREEN}$BANNER_FILE${NC}"
        echo -e "File size     : ${GREEN}$(du -h "$BANNER_FILE" | cut -f1)${NC}"
        echo -e "Last modified : ${GREEN}$(date -r "$BANNER_FILE" '+%Y-%m-%d %H:%M:%S')${NC}"
        echo -e "Status        : ${GREEN}Custom banner active${NC}"
    else
        echo -e "Banner file   : ${YELLOW}Not found${NC}"
        echo -e "Status        : ${YELLOW}Using default banner${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}========================================${NC}"
}

# Main function
main() {
    case "${1:-}" in
        "change")
            change_banner
            ;;
        "preview")
            preview_banner
            read -p "Press Enter to continue..."
            ;;
        "info")
            show_banner_info
            read -p "Press Enter to continue..."
            ;;
        "edit")
            edit_banner_file
            ;;
        "remove")
            remove_banner
            read -p "Press Enter to continue..."
            ;;
        *)
            main_menu
            ;;
    esac
}

# Run main function with arguments
main "$@"