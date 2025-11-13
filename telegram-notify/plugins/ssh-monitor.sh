#!/bin/sh
set -euf

# SSH Login Monitoring - OpenWrt Version
# Works with logread instead of /var/log/auth.log

. /usr/local/sbin/telegram-notify/core.sh || exit 1

[ "$TELEGRAM_ENABLED" != "1" ] && exit 0

monitor_ssh() {
    local failed_attempts failed_ips
    
    # Get logs from logread (last 100 lines)
    local logs=$(logread | tail -100)
    
    # Count failed SSH attempts (dropbear auth failures)
    failed_attempts=$(echo "$logs" | grep -i "dropbear.*failed\|dropbear.*root\|bad password" | wc -l || echo 0)
    
    if [ "$failed_attempts" -gt 3 ]; then
        if ! cache_get "ssh_failed_alert" >/dev/null 2>&1; then
            # Extract IPs from failed attempts
            failed_ips=$(echo "$logs" | grep -i "dropbear.*failed\|bad password" | \
                grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | sort | uniq -c | sort -rn | head -3 | \
                awk '{print "<code>" $2 "</code> (" $1 ")"}' | tr '\n' ' ')
            
            local msg="🔐 <b>SSH Failed Attempts</b>
<b>Attempts:</b> $failed_attempts
<b>IPs:</b> $failed_ips
<b>Time:</b> $(date '+%H:%M:%S')"
            
            send_message "$msg" "HTML"
            cache_set "ssh_failed_alert" "1" 1800
            log_msg "info" "SSH failed attempts detected: $failed_attempts"
        fi
    fi
    
    # Check for successful SSH logins
    local successful=$(echo "$logs" | grep -i "dropbear.*login\|accepted\|connection.*closed")
    
    if [ -n "$successful" ]; then
        if ! cache_get "ssh_login_recent" >/dev/null 2>&1; then
            local ip=$(echo "$successful" | tail -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "local")
            
            local msg="✅ <b>SSH Login</b>
<b>IP:</b> <code>$ip</code>
<b>Time:</b> $(date '+%H:%M:%S')"
            
            send_message "$msg" "HTML"
            cache_set "ssh_login_recent" "1" 900
            log_msg "info" "SSH login detected from: $ip"
        fi
    fi
}

case "${1:-monitor}" in
    monitor) monitor_ssh ;;
    *) monitor_ssh ;;
esac
