#!/bin/sh
set -euf
. /opt/telegram-notify/notify.sh

[ -n "$ACTION" ] || exit 0
[ -n "$ADDRESS" ] || exit 0

MAC=$(printf '%s' "$ADDRESS" | tr 'a-z' 'A-Z')
BAND=$(case "$INTERFACE" in *5g*) echo "5GHz" ;; *6g*) echo "6GHz" ;; *) echo "2.4GHz" ;; esac)

case "$ACTION" in
    add)
        if ! cache_get "wifi_$MAC" >/dev/null 2>&1; then
            notify "📱 <b>WiFi Connected</b>
<b>MAC:</b> <code>$MAC</code>
<b>Band:</b> $BAND"
            cache_set "wifi_$MAC" "1" 900
        fi
        ;;
    remove)
        notify "📵 <b>WiFi Disconnected</b>
<b>MAC:</b> <code>$MAC</code>"
        cache_del "wifi_$MAC"
        ;;
esac
