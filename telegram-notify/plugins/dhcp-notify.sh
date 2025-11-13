#!/bin/sh
set -euf

. /usr/local/sbin/telegram-notify/core.sh || exit 1

[ "$TELEGRAM_ENABLED" != "1" ] && exit 0

handle_dhcp_event() {
    local action="${ACTION:-}"
    local mac="${MACADDR:-}"
    local ip="${IPADDR:-}"
    local hostname="${HOSTNAME:-unknown}"

    [ -z "$action" ] || [ -z "$mac" ] || [ -z "$ip" ] && return 1

    mac=$(printf '%s' "$mac" | tr 'a-z' 'A-Z')

    case "$action" in
        add)
            if ! cache_get "dhcp_$mac" >/dev/null 2>&1; then
                local msg="🟢 <b>Device Connected</b>
<b>MAC:</b> <code>$mac</code>
<b>IP:</b> <code>$ip</code>
<b>Host:</b> <code>$hostname</code>"

                send_message "$msg" "HTML"
                cache_set "dhcp_$mac" "1" 600
            fi
            ;;
        remove)
            local msg="🔴 <b>Device Disconnected</b>
<b>MAC:</b> <code>$mac</code>
<b>IP:</b> <code>$ip</code>"

            send_message "$msg" "HTML"
            cache_del "dhcp_$mac"
            ;;
    esac
}

handle_dhcp_event
