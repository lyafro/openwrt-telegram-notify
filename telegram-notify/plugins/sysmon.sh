#!/bin/sh
set -euf
. /usr/local/sbin/telegram-notify/core.sh || exit 1
[ "$TELEGRAM_ENABLED" != "1" ] && exit 0

get_stats() {
    load=$(awk '{printf "%.1f, %.1f, %.1f", $1, $2, $3}' /proc/loadavg 2>/dev/null || echo "N/A")
    mem=$(awk '/MemTotal|MemFree/{a[$1]=$2} END {t=a["MemTotal:"]; f=a["MemFree:"]; u=t-f; p=int(u*100/t); printf "%d%% (%dM/%dM)", p, u/1024, t/1024}' /proc/meminfo 2>/dev/null || echo "N/A")
    uptime=$(awk '{printf "%d days", $1/86400}' /proc/uptime 2>/dev/null || echo "N/A")
    disk=$(df / 2>/dev/null | awk 'NR==2 {print $5}' || echo "N/A")

    send_message "🖥️ <b>System Status</b>

<b>Load:</b> $load
<b>Memory:</b> $mem
<b>Disk:</b> $disk
<b>Uptime:</b> $uptime
<b>Time:</b> $(date '+%Y-%m-%d %H:%M:%S')" "HTML"
}

check_alert() {
    mem_used=$(awk '/MemTotal|MemFree/{a[$1]=$2} END {print a["MemTotal:"]-a["MemFree:"]}' /proc/meminfo 2>/dev/null || echo 0)
    mem_total=$(awk '/MemTotal/{print $2}' /proc/meminfo 2>/dev/null || echo 1)
    mem_pct=$((mem_used * 100 / mem_total))

    if [ "$mem_pct" -gt 85 ]; then
        if ! cache_get "alert_mem" >/dev/null 2>&1; then
            send_message "⚠️ <b>Memory Alert</b>
<b>Used:</b> ${mem_pct}%" "HTML"
            cache_set "alert_mem" "1" 3600
        fi
    fi
}

case "${1:-stats}" in
    stats) get_stats ;;
    check-alert) check_alert ;;
    *) get_stats ;;
esac
