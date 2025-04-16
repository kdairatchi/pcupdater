#!/bin/bash

# ProxyChains config file location
CONF_FILE="/etc/proxychains4.conf"

# Temporary files
TEMP_FILE="/tmp/all_proxies.txt"
WORKING_FILE="/tmp/working_proxies.txt"
CHECKED_FILE="/tmp/checked_proxies.txt"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check proxy
check_proxy() {
    local ip=$1
    local port=$2
    local type=$3
    local timeout=3
    
    # Try to connect through the proxy
    if curl --silent --connect-timeout $timeout --max-time $timeout --proxy "$type://$ip:$port" "http://ifconfig.me" &>/dev/null; then
        echo -e "${GREEN}[+] Working proxy: $type $ip $port${NC}"
        echo "$type $ip $port" >> $WORKING_FILE
    else
        echo -e "${RED}[-] Failed proxy: $type $ip $port${NC}"
    fi
    echo "$type $ip $port" >> $CHECKED_FILE
}

# Function to fetch proxies from various sources
fetch_proxies() {
    echo -e "${YELLOW}[*] Gathering proxies from multiple sources...${NC}"
    
    # Clear previous files
    > $TEMP_FILE
    
    # Free proxy lists
    echo -e "${YELLOW}[*] Checking free-proxy-list.net${NC}"
    curl -s "https://free-proxy-list.net/" | grep -E -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}:[0-9]{1,5}' >> $TEMP_FILE
    
    echo -e "${YELLOW}[*] Checking sslproxies.org${NC}"
    curl -s "https://www.sslproxies.org/" | grep -E -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}:[0-9]{1,5}' >> $TEMP_FILE
    
    echo -e "${YELLOW}[*] Checking proxy-list.download${NC}"
    curl -s "https://www.proxy-list.download/api/v1/get?type=http" | grep -E -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}:[0-9]{1,5}' >> $TEMP_FILE
    curl -s "https://www.proxy-list.download/api/v1/get?type=https" | grep -E -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}:[0-9]{1,5}' >> $TEMP_FILE
    curl -s "https://www.proxy-list.download/api/v1/get?type=socks4" | grep -E -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}:[0-9]{1,5}' >> $TEMP_FILE
    curl -s "https://www.proxy-list.download/api/v1/get?type=socks5" | grep -E -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}:[0-9]{1,5}' >> $TEMP_FILE
    
    echo -e "${YELLOW}[*] Checking proxyscrape.com${NC}"
    curl -s "https://api.proxyscrape.com/v2/?request=getproxies&protocol=http&timeout=10000&country=all&ssl=all&anonymity=all" | grep -E -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}:[0-9]{1,5}' >> $TEMP_FILE
    curl -s "https://api.proxyscrape.com/v2/?request=getproxies&protocol=socks4&timeout=10000&country=all" | grep -E -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}:[0-9]{1,5}' >> $TEMP_FILE
    curl -s "https://api.proxyscrape.com/v2/?request=getproxies&protocol=socks5&timeout=10000&country=all" | grep -E -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}:[0-9]{1,5}' >> $TEMP_FILE
    
    # GitHub proxy lists
    echo -e "${YELLOW}[*] Checking GitHub proxy lists${NC}"
    curl -s "https://raw.githubusercontent.com/TheSpeedX/PROXY-List/master/http.txt" >> $TEMP_FILE
    curl -s "https://raw.githubusercontent.com/TheSpeedX/PROXY-List/master/socks4.txt" >> $TEMP_FILE
    curl -s "https://raw.githubusercontent.com/TheSpeedX/PROXY-List/master/socks5.txt" >> $TEMP_FILE
    curl -s "https://raw.githubusercontent.com/ShiftyTR/Proxy-List/master/http.txt" >> $TEMP_FILE
    curl -s "https://raw.githubusercontent.com/ShiftyTR/Proxy-List/master/https.txt" >> $TEMP_FILE
    curl -s "https://raw.githubusercontent.com/ShiftyTR/Proxy-List/master/socks4.txt" >> $TEMP_FILE
    curl -s "https://raw.githubusercontent.com/ShiftyTR/Proxy-List/master/socks5.txt" >> $TEMP_FILE
    curl -s "https://raw.githubusercontent.com/jetkai/proxy-list/main/online-proxies/txt/proxies-http.txt" >> $TEMP_FILE
    curl -s "https://raw.githubusercontent.com/jetkai/proxy-list/main/online-proxies/txt/proxies-https.txt" >> $TEMP_FILE
    curl -s "https://raw.githubusercontent.com/jetkai/proxy-list/main/online-proxies/txt/proxies-socks4.txt" >> $TEMP_FILE
    curl -s "https://raw.githubusercontent.com/jetkai/proxy-list/main/online-proxies/txt/proxies-socks5.txt" >> $TEMP_FILE
    
    # Remove duplicates and invalid formats
    sort -u $TEMP_FILE | grep -E '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}:[0-9]{1,5}$' > ${TEMP_FILE}.tmp
    mv ${TEMP_FILE}.tmp $TEMP_FILE
    
    echo -e "${GREEN}[+] Found $(wc -l < $TEMP_FILE) unique proxies${NC}"
}

# Backup original config
backup_config() {
    if [ -f "$CONF_FILE" ]; then
        cp "$CONF_FILE" "$CONF_FILE.bak"
        echo -e "${YELLOW}[*] Backup created at $CONF_FILE.bak${NC}"
    else
        echo -e "${RED}[-] Error: ProxyChains config file not found at $CONF_FILE${NC}"
        exit 1
    fi
}

# Update ProxyChains config
update_config() {
    # Clear existing proxies
    sed -i '/^socks[45]\|http/d' "$CONF_FILE"
    
    # Add new proxies
    if [ -s "$WORKING_FILE" ]; then
        cat "$WORKING_FILE" >> "$CONF_FILE"
        echo -e "${GREEN}[+] ProxyChains config updated with $(wc -l < $WORKING_FILE) working proxies${NC}"
    else
        echo -e "${RED}[-] No working proxies found${NC}"
    fi
}

# Main execution
echo -e "${YELLOW}ProxyChains Proxy Updater Script${NC}"
echo -e "${YELLOW}--------------------------------${NC}"

# Create empty files
> $WORKING_FILE
> $CHECKED_FILE

# Backup config
backup_config

# Fetch proxies
fetch_proxies

# Check proxies
echo -e "${YELLOW}[*] Checking proxies...${NC}"
counter=0
total=$(wc -l < $TEMP_FILE)

while read -r line; do
    ((counter++))
    ip=$(echo $line | cut -d: -f1)
    port=$(echo $line | cut -d: -f2)
    
    # Try different proxy types (prioritize SOCKS5)
    check_proxy $ip $port "socks5" &
    check_proxy $ip $port "socks4" &
    check_proxy $ip $port "http" &
    
    # Display progress
    echo -ne "${YELLOW}Checked $counter/$total proxies${NC}\r"
    
    # Limit concurrent checks to avoid overwhelming system
    if (( counter % 30 == 0 )); then
        wait
    fi
done < $TEMP_FILE

wait # Wait for all background processes to finish

# Update config
update_config

# Display summary
echo -e "\n${YELLOW}[*] Summary:${NC}"
echo -e "${GREEN}Working proxies: $(wc -l < $WORKING_FILE)${NC}"
echo -e "${RED}Failed proxies: $(( $(wc -l < $CHECKED_FILE) - $(wc -l < $WORKING_FILE) ))${NC}"

# Cleanup
rm $TEMP_FILE $WORKING_FILE $CHECKED_FILE
echo -e "${YELLOW}[*] Done!${NC}"
