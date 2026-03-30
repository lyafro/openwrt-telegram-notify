#!/bin/sh
set -euf
. /opt/telegram-notify/notify.sh

[ -n "$ACTION" ] || exit 0
[ -n "$MACADDR" ] || exit 0
[ -n "$IPADDR" ] || exit 0

MAC=$(printf '%s' "$MACADDR" | tr 'a-z' 'A-Z')
HOSTNAME="${HOSTNAME:-unknown}"

case "$ACTION" in
    add)
        if ! cache_get "dhcp_$MAC" >/dev/null 2>&1; then
            notify "🟢 <b>Device Connected</b>
<b>MAC:</b> <code>$MAC</code>
<b>IP:</b> <code>$IPADDR</code>
<b>Host:</b> <code>$(escape_html "$HOSTNAME")</code>"
            cache_set "dhcp_$MAC" "1" 600
        fi
        ;;
    remove)
        notify "🔴 <b>Device Disconnected</b>
<b>MAC:</b> <code>$MAC</code>
<b>IP:</b> <code>$IPADDR</code>"
        cache_del "dhcp_$MAC"
        ;;
esac
