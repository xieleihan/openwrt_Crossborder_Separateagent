#!/bin/sh

# MyProxy Apply Script
# This script applies proxy settings based on UCI configuration

. /lib/functions.sh

# Configuration
REDSOCKS_CONF="/tmp/redsocks_myproxy.conf"
REDSOCKS_PID="/var/run/redsocks_myproxy.pid"
SQUID_CONF="/tmp/squid_myproxy.conf"
SQUID_PID="/var/run/squid_myproxy.pid"

# Clear existing rules and configurations
cleanup_rules() {
    # Clear iptables rules
    iptables -t nat -F MYPROXY_REDIRECT 2>/dev/null
    iptables -t nat -X MYPROXY_REDIRECT 2>/dev/null
    iptables -t mangle -F MYPROXY_MARK 2>/dev/null
    iptables -t mangle -X MYPROXY_MARK 2>/dev/null
    
    # Stop redsocks if running
    if [ -f "$REDSOCKS_PID" ]; then
        kill $(cat "$REDSOCKS_PID") 2>/dev/null
        rm -f "$REDSOCKS_PID"
    fi
    
    # Stop squid if running
    if [ -f "$SQUID_PID" ]; then
        kill $(cat "$SQUID_PID") 2>/dev/null
        rm -f "$SQUID_PID"
    fi
    
    # Remove temporary config files
    rm -f "$REDSOCKS_CONF" "$SQUID_CONF"
}

# Initialize chains
init_chains() {
    iptables -t nat -N MYPROXY_REDIRECT 2>/dev/null
    iptables -t mangle -N MYPROXY_MARK 2>/dev/null
}

# Create redsocks configuration for SOCKS5 proxy
setup_redsocks() {
    local proxy_ip="$1"
    local proxy_port="$2"
    local local_port="$3"
    
    cat > "$REDSOCKS_CONF" << EOF
base {
    log_debug = off;
    log_info = on;
    log = stderr;
    daemon = on;
    pidfile = $REDSOCKS_PID;
    redirector = iptables;
}

redsocks {
    local_ip = 127.0.0.1;
    local_port = $local_port;
    ip = $proxy_ip;
    port = $proxy_port;
    type = socks5;
}
EOF
}

# Create squid configuration for HTTP proxy
setup_squid() {
    local proxy_ip="$1"
    local proxy_port="$2"
    local local_port="$3"
    
    cat > "$SQUID_CONF" << EOF
http_port $local_port transparent
cache_peer $proxy_ip parent $proxy_port 0 no-query default
never_direct allow all
pid_filename $SQUID_PID
access_log none
cache_log /dev/null
cache_store_log none
EOF
}

# Setup transparent proxy for HTTP traffic
setup_http_proxy() {
    local client_ip="$1"
    local proxy_ip="$2"
    local proxy_port="$3"
    local local_port="$4"
    
    # Setup squid as transparent proxy
    setup_squid "$proxy_ip" "$proxy_port" "$local_port"
    
    # Start squid
    squid -f "$SQUID_CONF" -D 2>/dev/null
    
    # Wait for squid to start
    sleep 2
    
    # Redirect HTTP traffic to local squid
    iptables -t nat -A MYPROXY_REDIRECT -s "$client_ip" -p tcp --dport 80 -j REDIRECT --to-port "$local_port"
    iptables -t nat -A MYPROXY_REDIRECT -s "$client_ip" -p tcp --dport 8080 -j REDIRECT --to-port "$local_port"
    
    echo "HTTP proxy setup for $client_ip -> $proxy_ip:$proxy_port (local port: $local_port)"
}

# Setup transparent proxy for SOCKS5 traffic
setup_socks5_proxy() {
    local client_ip="$1"
    local proxy_ip="$2"
    local proxy_port="$3"
    local local_port="$4"
    
    # Setup redsocks for SOCKS5
    setup_redsocks "$proxy_ip" "$proxy_port" "$local_port"
    
    # Start redsocks
    redsocks -c "$REDSOCKS_CONF" 2>/dev/null
    
    # Wait for redsocks to start
    sleep 2
    
    # Mark packets from specific client
    iptables -t mangle -A MYPROXY_MARK -s "$client_ip" -p tcp --dport 1:65535 -j MARK --set-mark "$local_port"
    
    # Redirect marked packets to redsocks
    iptables -t nat -A MYPROXY_REDIRECT -p tcp -m mark --mark "$local_port" -j REDIRECT --to-port "$local_port"
    
    # Exclude proxy server traffic to avoid loops
    iptables -t nat -I MYPROXY_REDIRECT -d "$proxy_ip" -j RETURN
    
    echo "SOCKS5 proxy setup for $client_ip -> $proxy_ip:$proxy_port (local port: $local_port)"
}

# Get next available port starting from 8000
get_next_port() {
    local start_port=8000
    local port=$start_port
    
    while netstat -ln | grep ":$port " > /dev/null 2>&1; do
        port=$((port + 1))
        if [ $port -gt 9000 ]; then
            echo "8000"  # fallback
            return
        fi
    done
    
    echo "$port"
}

# Function to handle each device proxy configuration
handle_device_proxy() {
    local section="$1"
    local ip proxy_ip proxy_port proxy_type enabled
    
    config_get ip "$section" "ip"
    config_get proxy_ip "$section" "proxy_ip"
    config_get proxy_port "$section" "proxy_port"
    config_get proxy_type "$section" "proxy_type"
    config_get enabled "$section" "enabled"
    
    # Check if enabled
    if [ "$enabled" != "1" ]; then
        echo "Skipping disabled proxy for $ip"
        return
    fi
    
    # Validate configuration
    if [ -z "$ip" ] || [ -z "$proxy_ip" ] || [ -z "$proxy_port" ]; then
        echo "Warning: Incomplete configuration for section $section"
        return
    fi
    
    # Set default proxy type if not specified
    if [ -z "$proxy_type" ]; then
        proxy_type="socks5"
    fi
    
    # Get next available local port
    local_port=$(get_next_port)
    
    # Apply proxy based on type
    case "$proxy_type" in
        "http")
            setup_http_proxy "$ip" "$proxy_ip" "$proxy_port" "$local_port"
            ;;
        "socks5")
            setup_socks5_proxy "$ip" "$proxy_ip" "$proxy_port" "$local_port"
            ;;
        *)
            echo "Warning: Unknown proxy type '$proxy_type' for $ip"
            return
            ;;
    esac
    
    echo "Proxy applied for $ip -> $proxy_ip:$proxy_port (type: $proxy_type)"
}

# Main execution
main() {
    echo "Starting MyProxy service..."
    
    # Check dependencies
    if ! command -v redsocks > /dev/null 2>&1; then
        echo "Warning: redsocks not found, SOCKS5 proxy will not work"
    fi
    
    if ! command -v squid > /dev/null 2>&1; then
        echo "Warning: squid not found, HTTP proxy will not work"
    fi
    
    # Cleanup existing rules
    cleanup_rules
    
    # Initialize chains
    init_chains
    
    # Load configuration and apply rules
    config_load myproxy
    config_foreach handle_device_proxy device_proxy
    
    # Insert the chains into main tables
    iptables -t nat -I PREROUTING -j MYPROXY_REDIRECT
    iptables -t mangle -I PREROUTING -j MYPROXY_MARK
    
    echo "MyProxy rules applied successfully"
}

# Run main function
main "$@"
