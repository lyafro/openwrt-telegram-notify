#!/bin/sh
set -euf
. /usr/local/sbin/telegram-notify/core.sh || exit 1
[ "$TELEGRAM_ENABLED" != "1" ] && exit 0

logs=$(logread | tail -100)

failed=$(echo "$logs" | grep -i "dropbear.*failed\|bad password" | wc -l || echo 0)
if [ "$failed" -gt 3 ] && ! cache_get "ssh_failed" >/dev/null 2>&1; then
    ips=$(echo "$logs" | grep -i "dropbear.*failed" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | sort | uniq -c | sort -rn | head -2 | awk '{print "<code>" $2 "</code>"}' | tr '
' ' ')
    send_message "🔐 <b>SSH Failed</b>
<b>Count:</b> $failed
<b>IPs:</b> $ips" "HTML"
    cache_set "ssh_failed" "1" 1800
fi
