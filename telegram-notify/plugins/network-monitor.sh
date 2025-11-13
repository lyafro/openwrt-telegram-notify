#!/bin/sh
set -euf

. /usr/local/sbin/telegram-notify/core.sh || exit 1

[ "$TELEGRAM_ENABLED" != "1" ] && exit 0

check_wan() {
    local iface="${1:-wan}"
    local force="${2:-0}"
    local ip
    
    ip=$(ip -4 addr show "$iface" 2>/dev/null | sed -n 's/.*inet \([0-9.]\+\).*/\1/p' | head -1 || echo "")
    
    log_msg "info" "WAN check: $iface IP=$ip (force=$force)"
    
    if [ -z "$ip" ]; then
        if ! cache_get "wan_down" >/dev/null 2>&1 || [ "$force" = "1" ]; then
            local msg="🔴 <b>WAN DOWN</b>
Interface: <code>$iface</code>"
            
            send_message "$msg" "HTML"
            cache_set "wan_down" "1" 600
        fi
    else
        cache_del "wan_down" 2>/dev/null || true
        if [ "$force" = "1" ]; then
            local msg="🟢 <b>WAN ACTIVE</b>
Interface: <code>$iface</code>
IP: <code>$ip</code>"
            
            send_message "$msg" "HTML"
        fi
    fi
}

check_interfaces() {
    local interfaces
    local msg="🌐 <b>Interface Status</b>

"
    local has_interfaces=0
    
    # Dynamically get all interfaces with IPv4 addresses that are UP
    interfaces=$(ip -4 -o addr show up 2>/dev/null | awk '{print $2}' | sort -u || echo "")
    
    if [ -z "$interfaces" ]; then
        log_msg "warn" "No interfaces with IPv4 found"
        return 1
    fi
    
    for iface in $interfaces; do
        local status ip
        
        # Skip loopback
        [ "$iface" = "lo" ] && continue
        
        status=$(ip link show "$iface" 2>/dev/null | grep -o 'UP\|DOWN' | head -1 || echo "")
        ip=$(ip -4 addr show "$iface" 2>/dev/null | sed -n 's/.*inet \([0-9.]\+\).*/\1/p' | head -1 || echo "")
        
        if [ -n "$status" ]; then
            local emoji="🟢"
            [ "$status" = "DOWN" ] && emoji="🔴"
            msg="${msg}${emoji} <b>$iface:</b> $status"
            [ -n "$ip" ] && msg="${msg} <code>$ip</code>"
            msg="${msg}
"
            has_interfaces=1
        fi
    done
    
    if [ "$has_interfaces" = "1" ]; then
        send_message "$msg" "HTML"
        log_msg "info" "Interface status sent"
    else
        log_msg "warn" "No interfaces found"
        return 1
    fi
}

case "${1:-all}" in
    wan-check) check_wan "${2:-wan}" 0 ;;
    wan-force) check_wan "${2:-wan}" 1 ;;
    all) check_interfaces ;;
    *) check_interfaces ;;
esac
