#!/bin/sh
set -euf

. /usr/local/sbin/telegram-bot/core.sh || exit 1

[ "$TELEGRAM_ENABLED" != "1" ] && exit 0

get_band() {
    case "$1" in
        *5g*) echo "5GHz" ;;
        *6g*) echo "6GHz" ;;
        *) echo "2.4GHz" ;;
    esac
}

handle_wifi_event() {
    local action="${ACTION:-}"
    local address="${ADDRESS:-}"
    local interface="${INTERFACE:-}"

    [ -z "$action" ] || [ -z "$address" ] || [ -z "$interface" ] && return 1

    address=$(printf '%s' "$address" | tr 'a-z' 'A-Z')
    local band=$(get_band "$interface")

    case "$action" in
        add)
            if ! cache_get "wifi_$address" >/dev/null 2>&1; then
                local msg="📱 <b>WiFi Connected</b>
<b>MAC:</b> <code>$address</code>
<b>Band:</b> $band"

                send_message "$msg" "HTML"
                cache_set "wifi_$address" "1" 900
            fi
            ;;
        remove)
            local msg="📵 <b>WiFi Disconnected</b>
<b>MAC:</b> <code>$address</code>"

            send_message "$msg" "HTML"
            cache_del "wifi_$address"
            ;;
    esac
}

handle_wifi_event
