#!/bin/sh
set -euf
. /usr/local/sbin/telegram-notify/core.sh

[ "$TELEGRAM_ENABLED" = "1" ] || exit 0

list_interfaces() {
    local msg="🌐 <b>Interface Status</b>

"

    for iface in $(ip -4 -o addr show up 2>/dev/null | awk '{print $2}' | sort -u); do
        [ "$iface" = "lo" ] && continue

        local status=$(ip link show "$iface" 2>/dev/null | grep -o 'UP' || echo "DOWN")
        local ip=$(ip -4 addr show "$iface" 2>/dev/null | sed -n 's/.*inet \([0-9.]\+\).*//p' | head -1)
        local emoji="🟢"
        [ "$status" = "DOWN" ] && emoji="🔴"

        msg="${msg}${emoji} <b>$iface:</b> $status"
        [ -n "$ip" ] && msg="${msg} <code>$ip</code>"
        msg="${msg}
"
    done

    send_message "$msg" "HTML"
}

list_interfaces
