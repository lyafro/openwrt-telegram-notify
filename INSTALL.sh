#!/bin/bash
set -euo pipefail

echo "Installing OpenWrt Telegram Notify v1.2..."

opkg update >/dev/null 2>&1 || true
opkg install curl ca-bundle cron >/dev/null 2>&1 || true

mkdir -p /usr/local/sbin/telegram-notify/{plugins,logs,cache,queue,config-backup}
mkdir -p /etc/hotplug.d/{dhcp,hostapd,iface}

chmod 755 /usr/local/sbin/telegram-notify
chmod 700 /usr/local/sbin/telegram-notify/{cache,logs,queue,config-backup}

cp telegram-notify/core.sh /usr/local/sbin/telegram-notify/
cp telegram-notify/plugins/*.sh /usr/local/sbin/telegram-notify/plugins/
chmod 755 /usr/local/sbin/telegram-notify/core.sh
chmod 755 /usr/local/sbin/telegram-notify/plugins/*.sh

cp hotplug/dhcp/98-telegram-notify /etc/hotplug.d/dhcp/
cp hotplug/hostapd/98-telegram-notify /etc/hotplug.d/hostapd/
cp hotplug/iface/98-telegram-notify /etc/hotplug.d/iface/
chmod 755 /etc/hotplug.d/{dhcp,hostapd,iface}/98-telegram-notify

mkdir -p /etc/config

if [ -f /etc/config/telegram-notify ]; then
    echo "⚠️ Config exists, backing up to telegram-notify.bak"
    cp /etc/config/telegram-notify /etc/config/telegram-notify.bak
    echo "ℹ️ Using existing config"
else
    echo "📝 Creating new config"
    cp config/telegram-notify /etc/config/telegram-notify
fi

chmod 600 /etc/config/telegram-notify

if ! grep -q "telegram-notify" /etc/crontabs/root 2>/dev/null; then
    echo "➕ Adding cron tasks"
    echo "" >> /etc/crontabs/root
    cat config/crontab.append >> /etc/crontabs/root
else
    echo "ℹ️ Cron tasks already present"
fi

/etc/init.d/cron enable
/etc/init.d/cron restart

echo ""
echo "✅ Installation complete!"
echo ""
echo "📋 Configuration:"
echo "   uci set telegram-notify.default.token='YOUR_TOKEN'"
echo "   uci set telegram-notify.default.chat_id='YOUR_CHAT_ID'"
echo "   uci set telegram-notify.default.enabled='1'"
echo "   uci commit telegram-notify"
echo ""
echo "🧪 Test:"
echo "   /usr/local/sbin/telegram-notify/plugins/sysmon.sh stats"
echo ""
echo "📊 View logs:"
echo "   tail -f /usr/local/sbin/telegram-notify/logs/bot.log"
