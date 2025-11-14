#!/bin/sh
set -euf
. /usr/local/sbin/telegram-notify/core.sh || exit 1
[ "$TELEGRAM_ENABLED" != "1" ] && exit 0

check_all() {
    interfaces=$(ip -4 -o addr show up 2>/dev/null | awk '{print $2}' | sort -u || echo "")
    [ -z "$interfaces" ] && return 1

    msg="🌐 <b>Interface Status</b>

"

    for iface in $interfaces; do
        [ "$iface" = "lo" ] && continue
        status=$(ip link show "$iface" 2>/dev/null | grep -o 'UP\|DOWN' | head -1 || echo "")
        ip=$(ip -4 addr show "$iface" 2>/dev/null | sed -n 's/.*inet \([0-9.]\+\).*//p' | head -1)

        [ -n "$status" ] && {
            emoji="🟢"
            [ "$status" = "DOWN" ] && emoji="🔴"
            msg="${msg}${emoji} <b>$iface:</b> $status"
            [ -n "$ip" ] && msg="${msg} <code>$ip</code>"
            msg="${msg}
"
        }
    done

    send_message "$msg" "HTML"
}

case "${1:-all}" in
    all) check_all ;;
    *) check_all ;;
esac
