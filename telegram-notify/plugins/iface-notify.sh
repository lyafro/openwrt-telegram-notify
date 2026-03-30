#!/bin/sh
set -euf
. /opt/telegram-notify/notify.sh

[ -n "$INTERFACE" ] || exit 0
[ -n "$ACTION" ] || exit 0

case "$ACTION" in
    ifup)
        local ip
        ip=$(ip -4 addr show "$INTERFACE" 2>/dev/null | sed -n 's/.*inet \([0-9.]\+\).*/\1/p' | head -1)
        [ -z "$ip" ] && exit 0

        if ! cache_get "iface_up_$INTERFACE" >/dev/null 2>&1; then
            notify "🟢 <b>Interface UP</b>
<b>Name:</b> <code>$(escape_html "$INTERFACE")</code>
<b>IP:</b> <code>$ip</code>"
            cache_set "iface_up_$INTERFACE" "1" 600
        fi
        ;;
    ifdown)
        if ! cache_get "iface_down_$INTERFACE" >/dev/null 2>&1; then
            notify "🔴 <b>Interface DOWN</b>
<b>Name:</b> <code>$(escape_html "$INTERFACE")</code>"
            cache_set "iface_down_$INTERFACE" "1" 600
        fi
        ;;
esac
