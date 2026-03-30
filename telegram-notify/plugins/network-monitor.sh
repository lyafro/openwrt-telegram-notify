#!/bin/sh
set -euf
. /opt/telegram-notify/notify.sh

list_interfaces() {
    local msg="🌐 <b>Interface Status</b>

"
    local count=0

    for iface in $(ip -4 -o addr show 2>/dev/null | awk '{print $2}' | sort -u); do
        [ "$iface" = "lo" ] && continue

        local status ip emoji
        status=$(ip link show "$iface" 2>/dev/null | grep -o 'UP' || echo "DOWN")
        ip=$(ip -4 addr show "$iface" 2>/dev/null | sed -n 's/.*inet \([0-9.]\+\).*/\1/p' | head -1)
        emoji="🟢"

        [ "$status" = "DOWN" ] && emoji="🔴"

        msg="$msg${emoji} <b>$(escape_html "$iface"):</b> $status"
        [ -n "$ip" ] && msg="$msg <code>$ip</code>"
        msg="$msg
"
        count=$((count + 1))
    done

    [ "$count" -gt 0 ] && notify "$msg"
}

list_interfaces
