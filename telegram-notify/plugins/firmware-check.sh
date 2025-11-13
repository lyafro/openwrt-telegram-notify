#!/bin/sh
set -euf

. /usr/local/sbin/telegram-notify/core.sh || exit 1

[ "$TELEGRAM_ENABLED" != "1" ] && exit 0

check_firmware() {
    [ -f "/etc/os-release" ] || return 1

    local version
    version=$(grep VERSION /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"' || echo "unknown")

    local msg="📦 <b>OpenWrt Version</b>
<b>Version:</b> <code>$version</code>
<b>Check:</b> $(date '+%Y-%m-%d %H:%M:%S')"

    send_message "$msg" "HTML"
    log_msg "info" "Firmware version sent: $version"
}

[ "$1" = "scheduled" ] && check_firmware
