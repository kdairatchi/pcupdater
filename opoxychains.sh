#!/bin/bash

# ==============================================
# ProxyChains Ultimate Proxy Manager
# Version 2.0 | By kdairatchi
# ==============================================

# Configuration
CONF_FILE="/etc/proxychains4.conf"
TEMP_DIR="/tmp/proxychains_manager"
ALL_PROXIES="$TEMP_DIR/all_proxies.txt"
WORKING_PROXIES="$TEMP_DIR/working_proxies.txt"
CHECKED_PROXIES="$TEMP_DIR/checked_proxies.txt"
LOG_FILE="$TEMP_DIR/proxy_manager.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ASCII Art Banner
function show_banner() {
    clear
    echo -e "${CYAN}"
    echo " ██████╗ ██████╗  ██████╗ ██╗  ██╗██╗   ██╗ ██████╗██╗  ██╗ █████╗ ██╗███╗   ██╗███████╗"
    echo "██╔═══██╗██╔══██╗██╔═══██╗╚██╗██╔╝╚██╗ ██╔╝██╔════╝██║  ██║██╔══██╗██║████╗  ██║██╔════╝"
    echo "██║   ██║██████╔╝██║   ██║ ╚███╔╝  ╚████╔╝ ██║     ███████║███████║██║██╔██╗ ██║███████╗"
    echo "██║   ██║██╔═══╝ ██║   ██║ ██╔██╗   ╚██╔╝  ██║     ██╔══██║██╔══██║██║██║╚██╗██║╚════██║"
    echo "╚██████╔╝██║     ╚██████╔╝██╔╝ ██╗   ██║   ╚██████╗██║  ██║██║  ██║██║██║ ╚████║███████║"
    echo " ╚═════╝ ╚═╝      ╚═════╝ ╚═╝  ╚═╝   ╚═╝    ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝╚══════╝"
    echo -e "${NC}"
    echo -e "${YELLOW}════════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}                   Ultimate Proxy Manager for ProxyChains${NC}"
    echo -e "${YELLOW}════════════════════════════════════════════════════════════════════════════════${NC}"
    echo
}

# Initialize working directory
function init_workspace() {
    mkdir -p "$TEMP_DIR"
    > "$ALL_PROXIES"
    > "$WORKING_PROXIES"
    > "$CHECKED_PROXIES"
    > "$LOG_FILE"
}

# Logging function
function log() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
    echo -e "$1"
}

# Check if running as root
function check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        log "${RED}This script must be run as root. Please use sudo.${NC}"
        exit 1
    fi
}

# Backup configuration
function backup_config() {
    if [ -f "$CONF_FILE" ]; then
        cp "$CONF_FILE" "$CONF_FILE.bak"
        log "${GREEN}[+] Configuration backed up to $CONF_FILE.bak${NC}"
    else
        log "${RED}[-] Error: ProxyChains config file not found at $CONF_FILE${NC}"
        exit 1
    fi
}

# Fetch proxies from various sources
function fetch_proxies() {
    local sources=(
        "free-proxy-list.net|https://free-proxy-list.net/"
        "sslproxies.org|https://www.sslproxies.org/"
        "proxy-list.download HTTP|https://www.proxy-list.download/api/v1/get?type=http"
        "proxy-list.download HTTPS|https://www.proxy-list.download/api/v1/get?type=https"
        "proxy-list.download SOCKS4|https://www.proxy-list.download/api/v1/get?type=socks4"
        "proxy-list.download SOCKS5|https://www.proxy-list.download/api/v1/get?type=socks5"
        "proxyscrape HTTP|https://api.proxyscrape.com/v2/?request=getproxies&protocol=http&timeout=10000&country=all&ssl=all&anonymity=all"
        "proxyscrape SOCKS4|https://api.proxyscrape.com/v2/?request=getproxies&protocol=socks4&timeout=10000&country=all"
        "proxyscrape SOCKS5|https://api.proxyscrape.com/v2/?request=getproxies&protocol=socks5&timeout=10000&country=all"
        "TheSpeedX HTTP|https://raw.githubusercontent.com/TheSpeedX/PROXY-List/master/http.txt"
        "TheSpeedX SOCKS4|https://raw.githubusercontent.com/TheSpeedX/PROXY-List/master/socks4.txt"
        "TheSpeedX SOCKS5|https://raw.githubusercontent.com/TheSpeedX/PROXY-List/master/socks5.txt"
        "ShiftyTR HTTP|https://raw.githubusercontent.com/ShiftyTR/Proxy-List/master/http.txt"
        "ShiftyTR HTTPS|https://raw.githubusercontent.com/ShiftyTR/Proxy-List/master/https.txt"
        "ShiftyTR SOCKS4|https://raw.githubusercontent.com/ShiftyTR/Proxy-List/master/socks4.txt"
        "ShiftyTR SOCKS5|https://raw.githubusercontent.com/ShiftyTR/Proxy-List/master/socks5.txt"
        "jetkai HTTP|https://raw.githubusercontent.com/jetkai/proxy-list/main/online-proxies/txt/proxies-http.txt"
        "jetkai HTTPS|https://raw.githubusercontent.com/jetkai/proxy-list/main/online-proxies/txt/proxies-https.txt"
        "jetkai SOCKS4|https://raw.githubusercontent.com/jetkai/proxy-list/main/online-proxies/txt/proxies-socks4.txt"
        "jetkai SOCKS5|https://raw.githubusercontent.com/jetkai/proxy-list/main/online-proxies/txt/proxies-socks5.txt"
    )

    log "${YELLOW}[*] Gathering proxies from multiple sources...${NC}"
    
    for source in "${sources[@]}"; do
        local name=${source%%|*}
        local url=${source#*|}
        log "${BLUE}[>] Checking $name...${NC}"
        curl -s "$url" | grep -E -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}:[0-9]{1,5}' >> "$ALL_PROXIES" 2>> "$LOG_FILE"
    done

    # Remove duplicates and invalid formats
    sort -u "$ALL_PROXIES" | grep -E '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}:[0-9]{1,5}$' > "${ALL_PROXIES}.tmp"
    mv "${ALL_PROXIES}.tmp" "$ALL_PROXIES"
    
    local count=$(wc -l < "$ALL_PROXIES")
    log "${GREEN}[+] Found $count unique proxies${NC}"
}

# Check proxy function
function check_proxy() {
    local ip=$1
    local port=$2
    local type=$3
    local timeout=5
    
    # Try to connect through the proxy
    if curl --silent --connect-timeout $timeout --max-time $timeout --proxy "$type://$ip:$port" "http://ifconfig.me" &>> "$LOG_FILE"; then
        log "${GREEN}[+] Working proxy: $type $ip $port${NC}"
        echo "$type $ip $port" >> "$WORKING_PROXIES"
    else
        log "${RED}[-] Failed proxy: $type $ip $port${NC}"
    fi
    echo "$type $ip $port" >> "$CHECKED_PROXIES"
}

# Check all proxies
function check_all_proxies() {
    local total=$(wc -l < "$ALL_PROXIES")
    local counter=0
    
    log "${YELLOW}[*] Checking $total proxies...${NC}"
    
    while read -r line; do
        ((counter++))
        local ip=$(echo "$line" | cut -d: -f1)
        local port=$(echo "$line" | cut -d: -f2)
        
        # Try different proxy types (prioritize SOCKS5)
        check_proxy "$ip" "$port" "socks5" &
        check_proxy "$ip" "$port" "socks4" &
        check_proxy "$ip" "$port" "http" &
        
        # Display progress
        echo -ne "${YELLOW}Checked $counter/$total proxies${NC}\r"
        
        # Limit concurrent checks
        if (( counter % 20 == 0 )); then
            wait
        fi
    done < "$ALL_PROXIES"

    wait
    echo -e "\n${GREEN}[+] Proxy checking completed!${NC}"
}

# Update ProxyChains configuration
function update_config() {
    # Clear existing proxies
    sed -i '/^socks[45]\|http/d' "$CONF_FILE"
    
    # Add new proxies
    if [ -s "$WORKING_PROXIES" ]; then
        sort -u "$WORKING_PROXIES" >> "$CONF_FILE"
        local count=$(wc -l < "$WORKING_PROXIES")
        log "${GREEN}[+] Updated $CONF_FILE with $count working proxies${NC}"
    else
        log "${RED}[-] No working proxies found to update configuration${NC}"
    fi
}

# Show statistics
function show_stats() {
    local total=$(wc -l < "$ALL_PROXIES" 2>/dev/null)
    local working=$(wc -l < "$WORKING_PROXIES" 2>/dev/null)
    local checked=$(wc -l < "$CHECKED_PROXIES" 2>/dev/null)
    
    echo -e "${YELLOW}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN} Proxy Statistics:${NC}"
    echo -e "${YELLOW}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}Total Proxies Found:${NC} $total"
    echo -e "${GREEN}Working Proxies:${NC} $working"
    echo -e "${RED}Failed Proxies:${NC} $(( checked - working ))"
    echo -e "${YELLOW}════════════════════════════════════════════════════════════════${NC}"
    echo
}

# Main menu
function main_menu() {
    while true; do
        show_banner
        show_stats
        
        echo -e "${CYAN}Main Menu:${NC}"
        echo -e "1) Fetch Fresh Proxies"
        echo -e "2) Check All Proxies"
        echo -e "3) Update ProxyChains Config"
        echo -e "4) View Working Proxies"
        echo -e "5) View All Proxies"
        echo -e "6) View Log"
        echo -e "7) Clean Workspace"
        echo -e "8) Exit"
        echo
        read -p "Select an option [1-8]: " choice
        
        case $choice in
            1)  # Fetch proxies
                init_workspace
                fetch_proxies
                ;;
            2)  # Check proxies
                if [ ! -s "$ALL_PROXIES" ]; then
                    log "${RED}[-] No proxies found. Please fetch proxies first.${NC}"
                    sleep 2
                    continue
                fi
                > "$WORKING_PROXIES"
                > "$CHECKED_PROXIES"
                check_all_proxies
                ;;
            3)  # Update config
                if [ ! -s "$WORKING_PROXIES" ]; then
                    log "${RED}[-] No working proxies found. Please check proxies first.${NC}"
                    sleep 2
                    continue
                fi
                backup_config
                update_config
                ;;
            4)  # View working proxies
                if [ -s "$WORKING_PROXIES" ]; then
                    echo -e "${GREEN}Working Proxies:${NC}"
                    cat "$WORKING_PROXIES" | nl
                else
                    log "${RED}[-] No working proxies found${NC}"
                fi
                read -p "Press Enter to continue..."
                ;;
            5)  # View all proxies
                if [ -s "$ALL_PROXIES" ]; then
                    echo -e "${BLUE}All Proxies:${NC}"
                    cat "$ALL_PROXIES" | nl
                else
                    log "${RED}[-] No proxies found${NC}"
                fi
                read -p "Press Enter to continue..."
                ;;
            6)  # View log
                if [ -s "$LOG_FILE" ]; then
                    echo -e "${YELLOW}Log File:${NC}"
                    cat "$LOG_FILE"
                else
                    log "${RED}[-] Log file is empty${NC}"
                fi
                read -p "Press Enter to continue..."
                ;;
            7)  # Clean workspace
                rm -rf "$TEMP_DIR"
                log "${GREEN}[+] Workspace cleaned${NC}"
                sleep 1
                ;;
            8)  # Exit
                log "${YELLOW}[*] Exiting ProxyChains Manager${NC}"
                exit 0
                ;;
            *)
                log "${RED}[-] Invalid option${NC}"
                sleep 1
                ;;
        esac
    done
}

# Main execution
check_root
init_workspace
main_menu
