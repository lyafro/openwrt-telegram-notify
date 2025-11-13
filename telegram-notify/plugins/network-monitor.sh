#!/bin/sh
set -euf

. /usr/local/sbin/telegram-notify/core.sh || exit 1

[ "$TELEGRAM_ENABLED" != "1" ] && exit 0

check_wan() {
    local iface="${1:-wan}"
    local force="${2:-0}"
    local ip

    ip=$(ip -4 addr show "$iface" 2>/dev/null | sed -n 's/.*inet \([0-9.]\+\).*//p' | head -1 || echo "")

    log_msg "info" "WAN check: $iface IP=$ip (force=$force)"

    if [ -z "$ip" ]; then
        if ! cache_get "wan_down" >/dev/null 2>&1 || [ "$force" = "1" ]; then
            local msg="🔴 <b>WAN DOWN</b>
Interface: <code>$iface</code>"

            send_message "$msg" "HTML"
            cache_set "wan_down" "1" 600
        fi
    else
        cache_del "wan_down" 2>/dev/null || true
        if [ "$force" = "1" ]; then
            local msg="🟢 <b>WAN ACTIVE</b>
Interface: <code>$iface</code>
IP: <code>$ip</code>"

            send_message "$msg" "HTML"
        fi
    fi
}

check_interfaces() {
    local msg="🌐 <b>Interface Status</b>

"

    for iface in lan wan wan2; do
        local status ip
        status=$(ip link show "$iface" 2>/dev/null | grep -o 'UP\|DOWN' | head -1 || echo "")
        ip=$(ip -4 addr show "$iface" 2>/dev/null | sed -n 's/.*inet \([0-9.]\+\).*//p' | head -1 || echo "")

        if [ -n "$status" ]; then
            local emoji="🟢"
            [ "$status" = "DOWN" ] && emoji="🔴"
            msg="${msg}${emoji} <b>$iface:</b> $status"
            [ -n "$ip" ] && msg="${msg} <code>$ip</code>"
            msg="${msg}
"
        fi
    done

    send_message "$msg" "HTML"
    log_msg "info" "Interface status sent"
}

case "${1:-all}" in
    wan-check) check_wan "${2:-wan}" 0 ;;
    wan-force) check_wan "${2:-wan}" 1 ;;
    all) check_interfaces ;;
    *) check_interfaces ;;
esac
