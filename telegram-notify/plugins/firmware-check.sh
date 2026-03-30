#!/bin/sh
set -euf
. /opt/telegram-notify/notify.sh

[ -f "/etc/os-release" ] || exit 0

VERSION=$(grep VERSION /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"' || echo "unknown")

notify "📦 <b>OpenWrt Version</b>
<b>Version:</b> <code>$VERSION</code>"
