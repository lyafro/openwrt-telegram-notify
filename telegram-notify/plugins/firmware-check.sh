#!/bin/sh
set -euf
. /usr/local/sbin/telegram-notify/core.sh || exit 1
[ "$TELEGRAM_ENABLED" != "1" ] && exit 0
[ -f "/etc/os-release" ] || exit 0

version=$(grep VERSION /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"' || echo "unknown")
send_message "📦 <b>OpenWrt Version</b>
<b>Version:</b> <code>$version</code>" "HTML"
