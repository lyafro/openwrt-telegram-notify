# openwrt-telegram-notify

Telegram notifications for OpenWrt routers.

## Install

```bash
cd /tmp && wget https://github.com/lyafro/openwrt-telegram-notify/archive/main.tar.gz -O main.tar.gz
tar xzf main.tar.gz && cd openwrt-telegram-notify-main && bash INSTALL.sh
```

## Setup

```bash
uci set telegram-notify.default.token='YOUR_BOT_TOKEN'
uci set telegram-notify.default.chat_id='YOUR_CHAT_ID'
uci set telegram-notify.default.enabled='1'
uci commit telegram-notify
```

## Test

```bash
/usr/local/sbin/telegram-notify/plugins/sysmon.sh stats
```

## Events

**Real-time (Hotplug):** Device connect/disconnect, WiFi join/leave, Interface up/down
**Periodic (Cron):** Memory alerts, System status, SSH attempts, Config changes, Queue processing

## Features

✅ Real-time Hotplug events
✅ Retry with exponential backoff
✅ Offline message queue
✅ syslog integration
✅ BusyBox compatible
✅ Dynamic interface detection
✅ OpenWrt 24.10 ready

## License

Public Domain
