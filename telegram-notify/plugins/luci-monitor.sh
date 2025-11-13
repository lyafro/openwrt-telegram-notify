#!/bin/sh
set -euf

# LuCI Login Monitoring - OpenWrt Version
# Uses netstat to detect web connections and logread for errors

. /usr/local/sbin/telegram-notify/core.sh || exit 1

[ "$TELEGRAM_ENABLED" != "1" ] && exit 0

monitor_luci() {
    local logs
    
    # Get recent logs from logread
    logs=$(logread | tail -50)
    
    # Check for failed HTTP auth attempts (uhttpd logs)
    local failed_count=$(echo "$logs" | grep -i "uhttpd.*403\|http.*403\|auth.*fail" | wc -l || echo 0)
    
    if [ "$failed_count" -gt 2 ]; then
        if ! cache_get "luci_failed_alert" >/dev/null 2>&1; then
            # Try to extract client IPs
            local failed_ips=$(netstat -tn 2>/dev/null | grep ":80 " | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -rn | head -3 | \
                awk '{print "<code>" $2 "</code>"}' | tr '\n' ' ' || echo "unknown")
            
            local msg="⚠️ <b>Web Admin Failed Logins</b>
<b>Attempts:</b> $failed_count
<b>Source IPs:</b> $failed_ips
<b>Time:</b> $(date '+%H:%M:%S')"
            
            send_message "$msg" "HTML"
            cache_set "luci_failed_alert" "1" 1800
            log_msg "info" "LuCI failed login attempts: $failed_count"
        fi
    fi
    
    # Check for successful logins (uhttpd session established)
    local successful=$(echo "$logs" | grep -i "uhttpd.*200\|session\|cookie")
    
    if [ -n "$successful" ]; then
        if ! cache_get "luci_login_recent" >/dev/null 2>&1; then
            # Get active web connections
            local client_ip=$(netstat -tn 2>/dev/null | grep ":80 " | awk '{print $5}' | cut -d: -f1 | head -1 || echo "unknown")
            
            local msg="✅ <b>Web Admin Access</b>
<b>Source IP:</b> <code>$client_ip</code>
<b>Time:</b> $(date '+%H:%M:%S')"
            
            send_message "$msg" "HTML"
            cache_set "luci_login_recent" "1" 600
            log_msg "info" "Web admin access from: $client_ip"
        fi
    fi
}

case "${1:-monitor}" in
    monitor) monitor_luci ;;
    *) monitor_luci ;;
esac
