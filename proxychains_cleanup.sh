#!/bin/bash
# proxychains_cleanup.sh - cleans old proxies from config

# Configuration
CONF_FILE="/etc/proxychains4.conf"
TEMP_DIR="/tmp/proxychains_manager"
WORKING_PROXIES="$TEMP_DIR/working_proxies.txt"
LOG_FILE="$TEMP_DIR/proxy_manager.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Logging
function log() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
    echo -e "$1"
}

# Safely update config - only modifies proxy list section
function update_config() {
    log "${YELLOW}[*] Updating config file...${NC}"
    
    # Create temp files
    TEMP_CONF="$TEMP_DIR/proxychains.temp"
    PROXY_LIST="$TEMP_DIR/proxy_list.temp"
    
    # Backup original
    cp "$CONF_FILE" "$CONF_FILE.bak"
    
    # Extract everything above the proxy list
    awk '/^\[ProxyList\]/ {exit} {print}' "$CONF_FILE" > "$TEMP_CONF"
    
    # Add fresh proxies
    echo -e "\n[ProxyList]" >> "$TEMP_CONF"
    if [ -s "$WORKING_PROXIES" ]; then
        sort -u "$WORKING_PROXIES" >> "$TEMP_CONF"
        log "${GREEN}[+] Added $(wc -l < "$WORKING_PROXIES") fresh proxies${NC}"
    else
        log "${RED}[-] No working proxies to add${NC}"
        echo "# No working proxies available" >> "$TEMP_CONF"
    fi
    
    # Replace config file
    mv "$TEMP_CONF" "$CONF_FILE"
    log "${GREEN}[+] Config file updated safely${NC}"
}

# Verify and clean proxies
function clean_proxies() {
    log "${YELLOW}[*] Verifying proxies...${NC}"
    
    FRESH_PROXIES="$TEMP_DIR/fresh_proxies.txt"
    > "$FRESH_PROXIES"
    
    if [ ! -s "$WORKING_PROXIES" ]; then
        log "${RED}[-] No proxies to verify${NC}"
        return
    fi
    
    while read -r line; do
        if [[ "$line" =~ ^(socks[45]|http)\ [0-9] ]]; then
            PROXY_TYPE=$(echo "$line" | awk '{print $1}')
            IP_PORT=$(echo "$line" | awk '{print $2}')
            
            if curl --silent --connect-timeout 5 --max-time 5 \
               --proxy "$PROXY_TYPE://$IP_PORT" "http://ifconfig.me" &>/dev/null; then
                echo "$line" >> "$FRESH_PROXIES"
            else
                log "${RED}[-] Removing dead proxy: $line${NC}"
            fi
        fi
    done < "$WORKING_PROXIES"
    
    mv "$FRESH_PROXIES" "$WORKING_PROXIES"
    log "${GREEN}[+] Verification complete. Working proxies: $(wc -l < "$WORKING_PROXIES")${NC}"
}

# Main execution
mkdir -p "$TEMP_DIR"
clean_proxies
update_config
