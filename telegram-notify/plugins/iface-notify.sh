#!/bin/sh
set -euf
. /usr/local/sbin/telegram-notify/core.sh

[ "$TELEGRAM_ENABLED" = "1" ] || exit 0
[ -n "$INTERFACE" ] && [ -n "$ACTION" ] || exit 0

case "$ACTION" in
    ifup)
        local ip=$(ip -4 addr show "$INTERFACE" 2>/dev/null | sed -n 's/.*inet \([0-9.]\+\).*//p' | head -1)
        [ -z "$ip" ] && exit 0
        cache_get "iface_up_$INTERFACE" >/dev/null 2>&1 && exit 0
        send_message "🟢 <b>Interface UP</b>
<b>Name:</b> <code>$INTERFACE</code>
<b>IP:</b> <code>$ip</code>" "HTML"
        cache_set "iface_up_$INTERFACE" "1" 600
        ;;
    ifdown)
        cache_get "iface_down_$INTERFACE" >/dev/null 2>&1 && exit 0
        send_message "🔴 <b>Interface DOWN</b>
<b>Name:</b> <code>$INTERFACE</code>" "HTML"
        cache_set "iface_down_$INTERFACE" "1" 600
        ;;
esac
