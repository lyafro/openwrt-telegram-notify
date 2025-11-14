#!/bin/sh
set -euf
. /usr/local/sbin/telegram-notify/core.sh

[ "$TELEGRAM_ENABLED" = "1" ] || exit 0
[ -n "$ACTION" ] && [ -n "$ADDRESS" ] && [ -n "$INTERFACE" ] || exit 0

MAC=$(printf '%s' "$ADDRESS" | tr 'a-z' 'A-Z')
BAND=$(case "$INTERFACE" in *5g*) echo "5GHz" ;; *6g*) echo "6GHz" ;; *) echo "2.4GHz" ;; esac)

case "$ACTION" in
    add)
        cache_get "wifi_$MAC" >/dev/null 2>&1 && exit 0
        send_message "📱 <b>WiFi Connected</b>
<b>MAC:</b> <code>$MAC</code>
<b>Band:</b> $BAND" "HTML"
        cache_set "wifi_$MAC" "1" 900
        ;;
    remove)
        send_message "📵 <b>WiFi Disconnected</b>
<b>MAC:</b> <code>$MAC</code>" "HTML"
        cache_del "wifi_$MAC"
        ;;
esac
