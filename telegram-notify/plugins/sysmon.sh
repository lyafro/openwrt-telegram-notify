#!/bin/sh
set -euf

. /usr/local/sbin/telegram-notify/core.sh || exit 1

[ "$TELEGRAM_ENABLED" != "1" ] && exit 0

get_stats() {
    local load
    load=$(awk '{printf "%.1f, %.1f, %.1f", $1, $2, $3}' /proc/loadavg 2>/dev/null || echo "N/A")

    local mem_info
    mem_info=$(awk '/MemTotal|MemFree/{a[$1]=$2} END {
        total=a["MemTotal:"]
        free=a["MemFree:"]
        used=total-free
        pct=int(used*100/total)
        printf "%d%% (%dM/%dM)", pct, used/1024, total/1024
    }' /proc/meminfo 2>/dev/null || echo "N/A")

    local uptime
    uptime=$(awk '{printf "%d days", $1/86400}' /proc/uptime 2>/dev/null || echo "N/A")

    local disk
    disk=$(df / 2>/dev/null | awk 'NR==2 {print $5}' || echo "N/A")

    local msg="🖥️ <b>System Status</b>

<b>Load:</b> $load
<b>Memory:</b> $mem_info
<b>Disk:</b> $disk
<b>Uptime:</b> $uptime
<b>Time:</b> $(date '+%Y-%m-%d %H:%M:%S')"

    send_message "$msg" "HTML"
    log_msg "info" "Stats sent"
}

check_memory_alert() {
    local mem_used mem_total mem_pct
    local force="${1:-0}"

    mem_used=$(awk '/MemTotal|MemFree/{a[$1]=$2} END {print a["MemTotal:"]-a["MemFree:"]}' /proc/meminfo 2>/dev/null || echo 0)
    mem_total=$(awk '/MemTotal/{print $2}' /proc/meminfo 2>/dev/null || echo 1)
    mem_pct=$((mem_used * 100 / mem_total))

    log_msg "info" "Memory check: ${mem_pct}% (force=$force)"

    if [ "$mem_pct" -gt 85 ] || [ "$force" = "1" ]; then
        if ! cache_get "alert_mem" >/dev/null 2>&1 || [ "$force" = "1" ]; then
            local msg="⚠️ <b>Memory Usage</b>
<b>Used:</b> ${mem_pct}%"

            send_message "$msg" "HTML"
            [ "$force" = "0" ] && cache_set "alert_mem" "1" 3600
        fi
    else
        log_msg "info" "Memory OK: ${mem_pct}%"
    fi
}

case "${1:-stats}" in
    stats) get_stats ;;
    check-alert) check_memory_alert 0 ;;
    force-alert) check_memory_alert 1 ;;
    *) get_stats ;;
esac
