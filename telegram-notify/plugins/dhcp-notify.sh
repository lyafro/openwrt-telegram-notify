#!/bin/sh
set -euf
. /usr/local/sbin/telegram-notify/core.sh

[ "$TELEGRAM_ENABLED" = "1" ] || exit 0
[ -n "$ACTION" ] && [ -n "$MACADDR" ] && [ -n "$IPADDR" ] || exit 0

MAC=$(printf '%s' "$MACADDR" | tr 'a-z' 'A-Z')
HOSTNAME="${HOSTNAME:-unknown}"

case "$ACTION" in
    add)
        cache_get "dhcp_$MAC" >/dev/null 2>&1 && exit 0
        send_message "🟢 <b>Device Connected</b>
<b>MAC:</b> <code>$MAC</code>
<b>IP:</b> <code>$IPADDR</code>
<b>Host:</b> <code>$HOSTNAME</code>" "HTML"
        cache_set "dhcp_$MAC" "1" 600
        ;;
    remove)
        send_message "🔴 <b>Device Disconnected</b>
<b>MAC:</b> <code>$MAC</code>
<b>IP:</b> <code>$IPADDR</code>" "HTML"
        cache_del "dhcp_$MAC"
        ;;
esac
