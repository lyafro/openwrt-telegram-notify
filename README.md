# openwrt-telegram-notify

Telegram notifications for OpenWrt routers.

## Quick Install

```bash
sh <(wget -O - https://raw.githubusercontent.com/lyafro/openwrt-telegram-notify/main/install.sh)
```

Or manual:

```bash
cd /tmp
wget https://github.com/lyafro/openwrt-telegram-notify/archive/main.tar.gz
tar xzf main.tar.gz
cd openwrt-telegram-notify-main
bash INSTALL.sh
```

## Setup

```bash
uci set telegram-notify.default.token='YOUR_BOT_TOKEN'
uci set telegram-notify.default.chat_id='YOUR_CHAT_ID'
uci set telegram-notify.default.enabled='1'
uci commit telegram-notify
```

Get bot token from @BotFather, chat ID from @userinfobot

## Test

```bash
/opt/telegram-notify/plugins/sysmon.sh stats
```

## Files

```
/opt/telegram-notify/
├── notify.sh          # Core (API, cache, queue, logging)
├── cron.sh            # Cron scheduler
└── plugins/           # Notification plugins

/etc/hotplug.d/iface/98-telegram-notify  # Hotplug handler
```

## License

Public Domain
