# openwrt-telegram-notify

Telegram notifications for OpenWrt with real-time Hotplug, retry logic, and offline queue.

## Install

```bash
cd /tmp
wget https://github.com/lyafro/openwrt-telegram-notify/archive/refs/heads/main.tar.gz
tar xzf main.tar.gz && cd openwrt-telegram-notify-main
bash INSTALL.sh
```

## Setup

```bash
uci set telegram-notify.default.token='YOUR_TOKEN'
uci set telegram-notify.default.chat_id='YOUR_CHAT_ID'
uci set telegram-notify.default.enabled='1'
uci commit telegram-notify

/usr/local/sbin/telegram-notify/plugins/sysmon.sh stats
```

## Events

**Real-time (Hotplug):**
- Device connect/disconnect
- WiFi client join/leave
- Interface up/down

**Periodic (Cron):**
- Memory alert (hourly)
- System status (9 AM)
- Firmware version (8 AM)
- Interface report (12 PM)
- SSH attempts (every 5 min)
- Config changes (every 3 min)
- Offline queue (every 5 min)

## Features

✅ Real-time Hotplug  
✅ Retry with backoff  
✅ Rate limit handling  
✅ Offline queue  
✅ syslog integration  
✅ BusyBox compatible  

## License

Public Domain.
