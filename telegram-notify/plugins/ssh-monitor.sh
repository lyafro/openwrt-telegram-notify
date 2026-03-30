#!/bin/sh
set -euf
. /opt/telegram-notify/notify.sh

LOGS=$(logread | tail -100)
FAILED=$(echo "$LOGS" | grep -ic "dropbear.*failed\|bad password" || echo 0)

if [ "$FAILED" -gt 3 ]; then
    if ! cache_get "ssh_failed" >/dev/null 2>&1; then
        notify "🔐 <b>SSH Failed Attempts</b>
<b>Count:</b> $FAILED"
        cache_set "ssh_failed" "1" 1800
    fi
fi
