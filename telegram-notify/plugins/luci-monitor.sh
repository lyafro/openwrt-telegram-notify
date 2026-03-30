#!/bin/sh
set -euf
. /opt/telegram-notify/notify.sh || exit 1

monitor_luci() {
    local logs failed_count failed_ips client_ip

    logs=$(logread | tail -50)

    failed_count=$(echo "$logs" | grep -i "uhttpd.*403\|http.*403\|auth.*fail" | wc -l || echo 0)

    if [ "$failed_count" -gt 2 ]; then
        if ! cache_get "luci_failed_alert" >/dev/null 2>&1; then
            failed_ips=$(netstat -tn 2>/dev/null | grep ":80 " | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -rn | head -3 | \
                awk '{print "<code>" $2 "</code>"}' | tr '\n' ' ' || echo "unknown")

            notify "⚠️ <b>Web Admin Failed Logins</b>
<b>Attempts:</b> $failed_count
<b>Source IPs:</b> $failed_ips
<b>Time:</b> $(date '+%H:%M:%S')"
            cache_set "luci_failed_alert" "1" 1800
            log_msg info "LuCI failed login attempts: $failed_count"
        fi
    fi

    successful=$(echo "$logs" | grep -i "uhttpd.*200\|session\|cookie")

    if [ -n "$successful" ]; then
        if ! cache_get "luci_login_recent" >/dev/null 2>&1; then
            client_ip=$(netstat -tn 2>/dev/null | grep ":80 " | awk '{print $5}' | cut -d: -f1 | head -1 || echo "unknown")

            notify "✅ <b>Web Admin Access</b>
<b>Source IP:</b> <code>$(escape_html "$client_ip")</code>
<b>Time:</b> $(date '+%H:%M:%S')"
            cache_set "luci_login_recent" "1" 600
            log_msg info "Web admin access from: $client_ip"
        fi
    fi
}

case "${1:-monitor}" in
    monitor) monitor_luci ;;
    *) monitor_luci ;;
esac
