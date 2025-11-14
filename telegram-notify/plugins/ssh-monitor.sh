#!/bin/sh
set -euf
. /usr/local/sbin/telegram-notify/core.sh

[ "$TELEGRAM_ENABLED" = "1" ] || exit 0

LOGS=$(logread | tail -100)
FAILED=$(echo "$LOGS" | grep -ic "dropbear.*failed\|bad password" || echo 0)

[ $FAILED -le 3 ] && exit 0
cache_get "ssh_failed" >/dev/null 2>&1 && exit 0

IPS=$(echo "$LOGS" | grep -i "dropbear.*failed" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | sort -u | head -3 | xargs)

send_message "🔐 <b>SSH Failed Attempts</b>
<b>Count:</b> $FAILED
<b>IPs:</b> <code>$IPS</code>" "HTML"
cache_set "ssh_failed" "1" 1800
