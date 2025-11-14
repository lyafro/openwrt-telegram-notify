#!/bin/sh
set -euf
. /usr/local/sbin/telegram-notify/core.sh || exit 1
[ "$TELEGRAM_ENABLED" != "1" ] && exit 0

action="${ACTION:-}" address="${ADDRESS:-}" interface="${INTERFACE:-}"
[ -z "$action" ] || [ -z "$address" ] || [ -z "$interface" ] && exit 0

address=$(printf '%s' "$address" | tr 'a-z' 'A-Z')
band=$(case "$interface" in *5g*) echo "5GHz" ;; *6g*) echo "6GHz" ;; *) echo "2.4GHz" ;; esac)

case "$action" in
    add)
        if ! cache_get "wifi_$address" >/dev/null 2>&1; then
            send_message "📱 <b>WiFi Connected</b>
<b>MAC:</b> <code>$address</code>
<b>Band:</b> $band" "HTML"
            cache_set "wifi_$address" "1" 900
        fi
        ;;
    remove)
        send_message "📵 <b>WiFi Disconnected</b>
<b>MAC:</b> <code>$address</code>" "HTML"
        cache_del "wifi_$address"
        ;;
esac
