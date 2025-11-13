#!/bin/bash
set -euo pipefail

echo "Installing OpenWrt Telegram Bot..."

opkg update >/dev/null 2>&1 || true
opkg install curl ca-bundle cron >/dev/null 2>&1 || true

mkdir -p /usr/local/sbin/telegram-bot/{plugins,logs,cache}
mkdir -p /etc/hotplug.d/{dhcp,hostapd}

chmod 755 /usr/local/sbin/telegram-bot
chmod 700 /usr/local/sbin/telegram-bot/cache
chmod 700 /usr/local/sbin/telegram-bot/logs

cp telegram-bot/core.sh /usr/local/sbin/telegram-bot/
cp telegram-bot/plugins/*.sh /usr/local/sbin/telegram-bot/plugins/
chmod 755 /usr/local/sbin/telegram-bot/core.sh
chmod 755 /usr/local/sbin/telegram-bot/plugins/*.sh

cp hotplug/dhcp/98-telegram-notify /etc/hotplug.d/dhcp/
cp hotplug/hostapd/98-telegram-notify /etc/hotplug.d/hostapd/
chmod 755 /etc/hotplug.d/dhcp/98-telegram-notify
chmod 755 /etc/hotplug.d/hostapd/98-telegram-notify

mkdir -p /etc/config
cp config/telegram-bot /etc/config/telegram-bot
chmod 600 /etc/config/telegram-bot

mkdir -p /etc/crontabs
if ! grep -q "telegram-bot" /etc/crontabs/root 2>/dev/null; then
    echo "" >> /etc/crontabs/root
    cat config/crontab.append >> /etc/crontabs/root
fi

/etc/init.d/cron enable
/etc/init.d/cron restart

echo "Installation complete!"
echo ""
echo "Configure: vi /etc/config/telegram-bot"
echo "Set token: uci set telegram-bot.default.token='YOUR_TOKEN'"
echo "Set chat_id: uci set telegram-bot.default.chat_id='YOUR_CHAT_ID'"
echo "Enable: uci set telegram-bot.default.enabled='1'"
echo "Commit: uci commit telegram-bot"
echo ""
echo "Test: /usr/local/sbin/telegram-bot/plugins/sysmon.sh stats"
echo "Logs: tail -f /usr/local/sbin/telegram-bot/logs/bot.log"
