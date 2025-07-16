#!/bin/sh

# MyProxy Status Script
# This script shows the current status of proxy configurations

. /lib/functions.sh

REDSOCKS_PID="/var/run/redsocks_myproxy.pid"
SQUID_PID="/var/run/squid_myproxy.pid"

echo "=== MyProxy Status ==="
echo

# Check if service is running
if [ -f "$REDSOCKS_PID" ] && kill -0 $(cat "$REDSOCKS_PID") 2>/dev/null; then
    echo "✓ Redsocks (SOCKS5) is running (PID: $(cat "$REDSOCKS_PID"))"
else
    echo "✗ Redsocks (SOCKS5) is not running"
fi

if [ -f "$SQUID_PID" ] && kill -0 $(cat "$SQUID_PID") 2>/dev/null; then
    echo "✓ Squid (HTTP) is running (PID: $(cat "$SQUID_PID"))"
else
    echo "✗ Squid (HTTP) is not running"
fi

echo

# Show current iptables rules
echo "=== Current iptables rules ==="
echo "NAT rules:"
iptables -t nat -L MYPROXY_REDIRECT -n 2>/dev/null | grep -v "^Chain\|^target" | head -10

echo
echo "Mangle rules:"
iptables -t mangle -L MYPROXY_MARK -n 2>/dev/null | grep -v "^Chain\|^target" | head -10

echo

# Show configuration
echo "=== Current Configuration ==="
config_load myproxy

show_device_proxy() {
    local section="$1"
    local ip proxy_ip proxy_port proxy_type enabled
    
    config_get ip "$section" "ip"
    config_get proxy_ip "$section" "proxy_ip"
    config_get proxy_port "$section" "proxy_port"
    config_get proxy_type "$section" "proxy_type"
    config_get enabled "$section" "enabled"
    
    if [ "$enabled" = "1" ]; then
        status="✓"
    else
        status="✗"
    fi
    
    echo "$status $ip -> $proxy_ip:$proxy_port ($proxy_type)"
}

config_foreach show_device_proxy device_proxy

echo

# Show listening ports
echo "=== Listening Ports ==="
netstat -ln | grep ":8[0-9][0-9][0-9] " | grep LISTEN

echo
echo "=== Log tail ==="
logread | grep -i myproxy | tail -10
