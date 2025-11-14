#!/bin/sh
set -euf
. /usr/local/sbin/telegram-notify/core.sh || exit 1
[ "$TELEGRAM_ENABLED" != "1" ] && exit 0

action="${ACTION:-}" mac="${MACADDR:-}" ip="${IPADDR:-}" hostname="${HOSTNAME:-unknown}"
[ -z "$action" ] || [ -z "$mac" ] || [ -z "$ip" ] && exit 0

mac=$(printf '%s' "$mac" | tr 'a-z' 'A-Z')

case "$action" in
    add)
        if ! cache_get "dhcp_$mac" >/dev/null 2>&1; then
            send_message "🟢 <b>Device Connected</b>
<b>MAC:</b> <code>$mac</code>
<b>IP:</b> <code>$ip</code>
<b>Host:</b> <code>$hostname</code>" "HTML"
            cache_set "dhcp_$mac" "1" 600
        fi
        ;;
    remove)
        send_message "🔴 <b>Device Disconnected</b>
<b>MAC:</b> <code>$mac</code>
<b>IP:</b> <code>$ip</code>" "HTML"
        cache_del "dhcp_$mac"
        ;;
esac
