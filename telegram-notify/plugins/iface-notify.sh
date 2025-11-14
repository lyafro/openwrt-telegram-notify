#!/bin/sh
set -euf
. /usr/local/sbin/telegram-notify/core.sh || exit 1
[ "$TELEGRAM_ENABLED" != "1" ] && exit 0

iface="${INTERFACE:-}" action="${ACTION:-}"
[ -z "$iface" ] && exit 0

case "$action" in
    ifup)
        ip=$(ip -4 addr show "$iface" 2>/dev/null | sed -n 's/.*inet \([0-9.]\+\).*//p' | head -1)
        if [ -n "$ip" ]; then
            if ! cache_get "iface_up_$iface" >/dev/null 2>&1; then
                send_message "🟢 <b>Interface UP</b>
<b>Name:</b> <code>$iface</code>
<b>IP:</b> <code>$ip</code>" "HTML"
                cache_set "iface_up_$iface" "1" 600
            fi
        fi
        ;;
    ifdown)
        if ! cache_get "iface_down_$iface" >/dev/null 2>&1; then
            send_message "🔴 <b>Interface DOWN</b>
<b>Name:</b> <code>$iface</code>" "HTML"
            cache_set "iface_down_$iface" "1" 600
        fi
        ;;
esac
