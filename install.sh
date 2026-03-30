#!/bin/sh
set -eu

REPO="lyafro/openwrt-telegram-notify"
BRANCH="main"
BOT_DIR="/opt/telegram-notify"

echo "Installing OpenWrt Telegram Notify..."

mkdir -p /var/lock
opkg update >/dev/null 2>&1 || true
opkg install curl ca-bundle cron >/dev/null 2>&1 || true

mkdir -p "$BOT_DIR"/plugins
mkdir -p "$BOT_DIR"/logs
mkdir -p "$BOT_DIR"/cache
mkdir -p "$BOT_DIR"/queue
mkdir -p "$BOT_DIR"/config-backup
chmod 755 "$BOT_DIR"
chmod 700 "$BOT_DIR/logs" "$BOT_DIR/cache" "$BOT_DIR/queue" "$BOT_DIR/config-backup"

mkdir -p /etc/hotplug.d

cd /tmp
rm -rf openwrt-telegram-notify-main

SHA=$(curl -s "https://api.github.com/repos/${REPO}/commits/${BRANCH}" | grep '"sha"' | head -1 | cut -d'"' -f4)
curl -sL "https://github.com/${REPO}/archive/${SHA}.tar.gz" | tar xz

cd openwrt-telegram-notify-${SHA}

cp telegram-notify/notify.sh "$BOT_DIR"/
cp telegram-notify/cron.sh "$BOT_DIR"/
for f in telegram-notify/plugins/*.sh; do
    cp "$f" "$BOT_DIR"/plugins/
done
chmod 755 "$BOT_DIR"/notify.sh "$BOT_DIR"/cron.sh
for f in "$BOT_DIR"/plugins/*.sh; do
    chmod 755 "$f"
done

mkdir -p /etc/hotplug.d/iface
mkdir -p /etc/hotplug.d/dhcp
mkdir -p /etc/hotplug.d/net
cp hotplug/98-telegram-notify /etc/hotplug.d/iface/98-telegram-notify
cp hotplug/98-telegram-notify /etc/hotplug.d/dhcp/98-telegram-notify
cp hotplug/98-telegram-notify /etc/hotplug.d/net/98-telegram-notify
chmod 755 /etc/hotplug.d/iface/98-telegram-notify
chmod 755 /etc/hotplug.d/dhcp/98-telegram-notify
chmod 755 /etc/hotplug.d/net/98-telegram-notify

mkdir -p /etc/config
if [ ! -f /etc/config/telegram-notify ]; then
    cp config/telegram-notify /etc/config/
fi
chmod 600 /etc/config/telegram-notify

if ! grep -q "telegram-notify" /etc/crontabs/root 2>/dev/null; then
    echo "" >> /etc/crontabs/root
    cat config/crontab.append >> /etc/crontabs/root
fi

/etc/init.d/cron enable 2>/dev/null || true
/etc/init.d/cron restart 2>/dev/null || true

rm -rf /tmp/openwrt-telegram-notify-main

echo "✅ Installed to $BOT_DIR"
