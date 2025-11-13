#!/bin/bash
set -euo pipefail

echo "Installing OpenWrt Telegram Notify..."

opkg update >/dev/null 2>&1 || true
opkg install curl ca-bundle cron >/dev/null 2>&1 || true

mkdir -p /usr/local/sbin/telegram-notify/{plugins,logs,cache}
mkdir -p /etc/hotplug.d/{dhcp,hostapd}

chmod 755 /usr/local/sbin/telegram-notify
chmod 700 /usr/local/sbin/telegram-notify/cache
chmod 700 /usr/local/sbin/telegram-notify/logs

cp telegram-notify/core.sh /usr/local/sbin/telegram-notify/
cp telegram-notify/plugins/*.sh /usr/local/sbin/telegram-notify/plugins/
chmod 755 /usr/local/sbin/telegram-notify/core.sh
chmod 755 /usr/local/sbin/telegram-notify/plugins/*.sh

cp hotplug/dhcp/98-telegram-notify /etc/hotplug.d/dhcp/
cp hotplug/hostapd/98-telegram-notify /etc/hotplug.d/hostapd/
chmod 755 /etc/hotplug.d/dhcp/98-telegram-notify
chmod 755 /etc/hotplug.d/hostapd/98-telegram-notify

mkdir -p /etc/config
cp config/telegram-notify /etc/config/telegram-notify
chmod 600 /etc/config/telegram-notify

mkdir -p /etc/crontabs
if ! grep -q "telegram-notify" /etc/crontabs/root 2>/dev/null; then
    echo "" >> /etc/crontabs/root
    cat config/crontab.append >> /etc/crontabs/root
fi

/etc/init.d/cron enable
/etc/init.d/cron restart

echo "Installation complete!"
echo ""
echo "Configure: vi /etc/config/telegram-notify"
echo "Set token: uci set telegram-notify.default.token='YOUR_TOKEN'"
echo "Set chat_id: uci set telegram-notify.default.chat_id='YOUR_CHAT_ID'"
echo "Enable: uci set telegram-notify.default.enabled='1'"
echo "Commit: uci commit telegram-notify"
echo ""
echo "Test: /usr/local/sbin/telegram-notify/plugins/sysmon.sh stats"
echo "Logs: tail -f /usr/local/sbin/telegram-notify/logs/bot.log"
