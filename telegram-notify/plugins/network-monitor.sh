#!/bin/sh
set -euf
. /usr/local/sbin/telegram-notify/core.sh

[ "$TELEGRAM_ENABLED" = "1" ] || exit 0

list_interfaces() {
    local msg="🌐 <b>Interface Status</b>

"
    local count=0

    for iface in $(ip -4 -o addr show 2>/dev/null | awk '{print $2}' | sort -u); do
        [ "$iface" = "lo" ] && continue

        local status=$(ip link show "$iface" 2>/dev/null | grep -o 'UP' || echo "DOWN")
        local ip=$(ip -4 addr show "$iface" 2>/dev/null | sed -n 's/.*inet \([0-9.]\+\).*//p' | head -1)
        local emoji="🟢"

        if [ "$status" = "DOWN" ]; then
            emoji="🔴"
        fi

        msg="$msg${emoji} <b>$iface:</b> $status"
        if [ -n "$ip" ]; then
            msg="$msg <code>$ip</code>"
        fi
        msg="$msg
"
        count=$((count + 1))
    done

    if [ $count -gt 0 ]; then
        send_message "$msg" "HTML"
    fi
}

list_interfaces
