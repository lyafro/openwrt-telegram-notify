#!/bin/bash
set -euo pipefail

echo "Installing OpenWrt Telegram Notify..."

opkg update >/dev/null 2>&1 || true
opkg install curl ca-bundle cron >/dev/null 2>&1 || true

mkdir -p /usr/local/sbin/telegram-notify/{plugins,logs,cache,queue,config-backup}
chmod 755 /usr/local/sbin/telegram-notify
chmod 700 /usr/local/sbin/telegram-notify/{cache,logs,queue,config-backup}

mkdir -p /etc/hotplug.d/{dhcp,hostapd,iface}

cp telegram-notify/core.sh /usr/local/sbin/telegram-notify/
cp telegram-notify/plugins/*.sh /usr/local/sbin/telegram-notify/plugins/
chmod 755 /usr/local/sbin/telegram-notify/core.sh
chmod 755 /usr/local/sbin/telegram-notify/plugins/*.sh

cp hotplug/*/* /etc/hotplug.d/
find /etc/hotplug.d -name "98-telegram-notify" -exec chmod 755 {} +

mkdir -p /etc/config
if [ ! -f /etc/config/telegram-notify ]; then
    cp config/telegram-notify /etc/config/
fi
chmod 600 /etc/config/telegram-notify

if ! grep -q "telegram-notify" /etc/crontabs/root 2>/dev/null; then
    echo "" >> /etc/crontabs/root
    cat config/crontab.append >> /etc/crontabs/root
fi

/etc/init.d/cron enable
/etc/init.d/cron restart

echo "✅ Done"
