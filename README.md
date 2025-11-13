# openwrt-telegram-notify

[![License: Public Domain](https://img.shields.io/badge/License-Public%20Domain-blue.svg)](LICENSE)
[![OpenWrt](https://img.shields.io/badge/OpenWrt-19.07%2B-blue)](https://openwrt.org)
[![Shell Script](https://img.shields.io/badge/Language-Shell%20Script-green)](https://www.shellscript.sh)

Lightweight Telegram notifications for OpenWrt routers. Real-time alerts for device connections, WiFi events, system monitoring, and network status.

## 🚀 Quick Start

### Direct from Router

```bash
cd /tmp
wget https://github.com/lyafro/openwrt-telegram-notify/archive/refs/heads/main.tar.gz -O main.tgz
tar xzf main.tgz && cd openwrt-telegram-notify-main
bash INSTALL.sh
```

### From PC

```bash
git clone https://github.com/lyafro/openwrt-telegram-notify.git
cd openwrt-telegram-notify
bash INSTALL.sh
```

## ⚙️ Setup (5 Steps)

**1. Create Bot**
- Message [@BotFather](https://t.me/botfather): `/newbot`
- Save your **API Token**

**2. Get Chat ID**
```bash
curl "https://api.telegram.org/bot<TOKEN>/getUpdates"
```

**3. Configure Router**
```bash
uci set telegram-notify.default.token='YOUR_TOKEN'
uci set telegram-notify.default.chat_id='YOUR_CHAT_ID'
uci set telegram-notify.default.enabled='1'
uci commit telegram-notify
```

**4. Verify**
```bash
uci show telegram-notify.default
```

**5. Test**
```bash
/usr/local/sbin/telegram-notify/plugins/sysmon.sh stats
```

## 📊 Events

| Event | Description |
|-------|-------------|
| 🟢 Device Connected | New DHCP lease |
| 🔴 Device Disconnected | DHCP lease expired |
| 📱 WiFi Join | New WiFi association |
| 📵 WiFi Leave | WiFi disassociation |
| 🖥️ System Status | CPU, memory, disk, uptime |
| ⚠️ Memory Alert | Usage >85% |
| 🌐 WAN Status | Internet changes |
| 🔴 Interface Down | Network failures |
| 📦 Firmware Version | OpenWrt version |

## 🔧 Usage

```bash
# System status
/usr/local/sbin/telegram-notify/plugins/sysmon.sh stats

# Memory check
/usr/local/sbin/telegram-notify/plugins/sysmon.sh check-alert

# WAN status
/usr/local/sbin/telegram-notify/plugins/network-monitor.sh wan-check

# All interfaces
/usr/local/sbin/telegram-notify/plugins/network-monitor.sh all

# Custom message
. /usr/local/sbin/telegram-notify/core.sh
send_message "Message"
```

## 📋 Requirements

- OpenWrt 19.07+
- Packages: `curl`, `ca-bundle`, `cron`
- Internet connection

## 🔒 Security

- ✅ Config protected (600 permissions)
- ✅ No credentials in logs
- ✅ Request timeouts (10s)
- ✅ Lock mechanism
- ✅ Log rotation with gzip

## 🐛 Troubleshooting

**No messages?**
```bash
ping 8.8.8.8
uci show telegram-notify.default
tail -f /usr/local/sbin/telegram-notify/logs/bot.log
curl -X GET "https://api.telegram.org/bot<TOKEN>/getMe"
```

**High memory?**
- Reduce cron frequency
- Clear logs: `rm /usr/local/sbin/telegram-notify/logs/bot.log*`

**Cron not running?**
```bash
/etc/init.d/cron enable
/etc/init.d/cron start
logread | grep CRON
```

## 🎯 Advanced

**Customize cron schedule:**
```bash
crontab -e
# Edit intervals and save
/etc/init.d/cron restart
```

**Add custom notification:**
```bash
cat > /usr/local/sbin/telegram-notify/plugins/custom.sh << 'EOF'
#!/bin/sh
set -euf
. /usr/local/sbin/telegram-notify/core.sh || exit 1
[ "$TELEGRAM_ENABLED" = "1" ] && send_message "Custom event"
EOF
chmod 755 /usr/local/sbin/telegram-notify/plugins/custom.sh
```

**Disable specific events:**
```bash
crontab -e
# Comment out unwanted lines and save
```

## 📊 Cron Schedule

```
*/5  * * * *  WAN check (5 min)
0    * * * *  Memory alert (hourly)
0    9 * * *  System status (9 AM)
0    8 * * *  Firmware check (8 AM)
0   12 * * *  Interface status (12 PM)
```

## 📂 Structure

```
├── telegram-notify/
│   ├── core.sh              # Main engine
│   └── plugins/
│       ├── dhcp-notify.sh   # Device events
│       ├── wifi-notify.sh   # WiFi events
│       ├── sysmon.sh        # System monitoring
│       ├── network-monitor.sh
│       └── firmware-check.sh
├── hotplug/
│   ├── dhcp/98-telegram-notify
│   └── hostapd/98-telegram-notify
└── config/telegram-notify
```

## 📝 License

Public Domain. Free to use and modify.

## 📖 Links

- [OpenWrt Docs](https://openwrt.org/docs/start)
- [Telegram Bot API](https://core.telegram.org/bots/api)
- [Hotplug Docs](https://openwrt.org/docs/guide-user/base-system/hotplug)

---

**Version:** 1.0.1 | **OpenWrt:** 19.07+
