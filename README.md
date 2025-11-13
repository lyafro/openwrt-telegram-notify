# openwrt-telegram-notify

[![License: Public Domain](https://img.shields.io/badge/License-Public%20Domain-blue.svg)](LICENSE)
[![OpenWrt](https://img.shields.io/badge/OpenWrt-19.07%2B-blue)](https://openwrt.org)
[![Shell Script](https://img.shields.io/badge/Language-Shell%20Script-green)](https://www.shellscript.sh)

Lightweight and secure Telegram notifications for OpenWrt routers. Get real-time alerts for device connections, WiFi events, system resource changes, and network status updates.

## 🚀 Quick Start

### Direct Installation on Router

```bash
# Download and extract
cd /tmp
wget https://github.com/lyafro/openwrt-telegram-notify/archive/refs/heads/main.zip
unzip main.zip
cd openwrt-telegram-notify-main

# Install
bash INSTALL.sh
```

### From Local Machine

```bash
# Clone repository
git clone https://github.com/lyafro/openwrt-telegram-notify.git
cd openwrt-telegram-notify

# Transfer to router via wget
scp openwrt-telegram-notify.tar.gz root@ROUTER_IP:/tmp/
# OR
ssh root@ROUTER_IP "cd /tmp && wget https://github.com/lyafro/openwrt-telegram-notify/archive/refs/heads/main.zip && unzip main.zip && cd openwrt-telegram-notify-main && bash INSTALL.sh"
```

## ⚙️ Configuration

### 1. Create Telegram Bot

Message [@BotFather](https://t.me/botfather) on Telegram:

```
/newbot
```

Follow the prompts and save your **API Token**.

### 2. Get Chat ID

```bash
curl "https://api.telegram.org/bot<YOUR_TOKEN>/getUpdates"
```

Look for `"id": <YOUR_CHAT_ID>` in the response.

### 3. Configure on Router

```bash
# Set token
uci set telegram-notify.default.token='123456:ABCdefGHIjklmnoPQRstuvWXYZ'

# Set chat ID
uci set telegram-notify.default.chat_id='987654321'

# Enable notifications
uci set telegram-notify.default.enabled='1'

# Apply changes
uci commit telegram-notify
```

### 4. Verify Configuration

```bash
uci show telegram-notify.default
```

### 5. Test

```bash
/usr/local/sbin/telegram-notify/plugins/sysmon.sh stats
```

You should receive a system status message in Telegram.

## 📊 Features

### Event Notifications

| Event | Plugin | Description |
|-------|--------|-------------|
| 🟢 Device Connected | dhcp-notify.sh | New DHCP lease acquired |
| 🔴 Device Disconnected | dhcp-notify.sh | DHCP lease expired |
| 📱 WiFi Client Join | wifi-notify.sh | New WiFi association |
| 📵 WiFi Client Leave | wifi-notify.sh | WiFi disassociation |
| 🖥️ System Status | sysmon.sh | CPU, memory, disk, uptime |
| ⚠️ Memory Alert | sysmon.sh | High memory usage (>85%) |
| 🌐 WAN Status | network-monitor.sh | Internet connection changes |
| 🔴 Interface Down | network-monitor.sh | Network interface failures |
| 📦 Firmware Version | firmware-check.sh | OpenWrt version tracking |

### Automatic Monitoring Schedule

By default, the following cron tasks are enabled:

```
*/5  * * * *  WAN connectivity check (every 5 minutes)
0    * * * *  Memory alert check (hourly)
0    9 * * *  System status report (daily 9:00 AM)
0    8 * * *  Firmware version check (daily 8:00 AM)
0   12 * * *  Interface status report (daily 12:00 PM)
```

## 🔧 Usage

### Manual Commands

```bash
# System status snapshot
/usr/local/sbin/telegram-notify/plugins/sysmon.sh stats

# Check for memory alerts
/usr/local/sbin/telegram-notify/plugins/sysmon.sh check-alert

# Check WAN status
/usr/local/sbin/telegram-notify/plugins/network-monitor.sh wan-check

# Check all interfaces
/usr/local/sbin/telegram-notify/plugins/network-monitor.sh all

# Send custom message from terminal
. /usr/local/sbin/telegram-notify/core.sh
send_message "Custom notification message"
```

### View Logs

```bash
# Last 50 lines
tail -50 /usr/local/sbin/telegram-notify/logs/bot.log

# Follow in real-time
tail -f /usr/local/sbin/telegram-notify/logs/bot.log
```

### Manage Cron Tasks

```bash
# View all cron tasks
crontab -l

# Edit cron tasks
crontab -e

# Restart cron service
/etc/init.d/cron restart
```

### Disable/Enable Notifications

```bash
# Disable
uci set telegram-notify.default.enabled='0'
uci commit telegram-notify

# Enable
uci set telegram-notify.default.enabled='1'
uci commit telegram-notify
```

## 🔒 Security

- ✅ Configuration stored with restricted permissions (mode 600)
- ✅ Cache and logs protected (mode 700)
- ✅ No credentials in log files
- ✅ Request timeouts on API calls (10 seconds)
- ✅ URL-encoded data protection
- ✅ Lock mechanism prevents race conditions
- ✅ Automatic log rotation with gzip compression
- ✅ Minimal dependencies (curl, ca-bundle, cron)

### Best Practices

1. **Use App Passwords** - For Gmail or other 2FA-enabled services
2. **Restrict Permissions** - Review `/etc/config/telegram-notify`
3. **Regular Updates** - Check for new versions of OpenWrt
4. **Monitor Logs** - Review `/usr/local/sbin/telegram-notify/logs/bot.log` regularly
5. **Test Configuration** - Run manual tests after setup


## 📋 System Requirements

- **OpenWrt/LEDE** version 19.07 or later
- **Packages**: `curl`, `ca-bundle`, `cron`
- **Storage**: ~50 KB (after installation)
- **RAM**: ~1 MB average
- **Internet**: Active connection for Telegram API

### Install Dependencies Manually

```bash
opkg update
opkg install curl ca-bundle cron
```

## 🐛 Troubleshooting

### Messages Not Sending

1. **Check Internet Connection**
   ```bash
   ping 8.8.8.8
   ping api.telegram.org
   ```

2. **Verify Configuration**
   ```bash
   uci show telegram-notify.default
   ```

3. **Test API Token**
   ```bash
   curl -X GET "https://api.telegram.org/bot<YOUR_TOKEN>/getMe"
   ```

4. **Check Logs**
   ```bash
   tail -f /usr/local/sbin/telegram-notify/logs/bot.log
   ```

### High Memory Usage

- Reduce cron frequency (increase intervals)
- Disable unused plugins by commenting cron lines
- Clear old logs: `rm /usr/local/sbin/telegram-notify/logs/bot.log*`

### Cannot Transfer File via SCP

Use wget instead:

```bash
# On router
cd /tmp
wget https://github.com/lyafro/openwrt-telegram-notify/archive/refs/heads/main.zip
unzip main.zip
cd openwrt-telegram-notify-main
bash INSTALL.sh
```

### Cron Tasks Not Running

```bash
# Verify cron is enabled and running
/etc/init.d/cron enable
/etc/init.d/cron start

# Check cron logs
logread | grep CRON
```

### Strange Behavior After Update

```bash
# Clear cache
rm -rf /usr/local/sbin/telegram-notify/cache/*

# Restart services
/etc/init.d/cron restart
```

## 🎯 Advanced Configuration

### Customize Cron Schedule

Edit `/etc/crontabs/root` and modify timing:

```bash
# Check WAN every 10 minutes (instead of 5)
*/10 * * * * /usr/local/sbin/telegram-notify/plugins/network-monitor.sh wan-check >/dev/null 2>&1

# System status every 6 hours instead of daily
0 */6 * * * /usr/local/sbin/telegram-notify/plugins/sysmon.sh stats >/dev/null 2>&1
```

Then restart cron:
```bash
/etc/init.d/cron restart
```

### Add Custom Notifications

Create `/usr/local/sbin/telegram-notify/plugins/custom.sh`:

```bash
#!/bin/sh
set -euf

. /usr/local/sbin/telegram-notify/core.sh || exit 1

[ "$TELEGRAM_ENABLED" != "1" ] && exit 0

# Your custom logic here
local msg="🔧 <b>Custom Event</b>
Custom data here"

send_message "$msg" "HTML"
```

Make it executable:
```bash
chmod 755 /usr/local/sbin/telegram-notify/plugins/custom.sh
```

Add to crontab:
```bash
0 10 * * * /usr/local/sbin/telegram-notify/plugins/custom.sh >/dev/null 2>&1
```

### Disable Specific Event Types

Comment out unwanted cron lines:

```bash
crontab -e

# Disable WAN checks (add # at start of line)
#*/5 * * * * /usr/local/sbin/telegram-notify/plugins/network-monitor.sh wan-check >/dev/null 2>&1

# Save and exit
```

## 📊 Performance Impact

| Metric | Impact |
|--------|--------|
| CPU Usage | Minimal (~0.1% per check) |
| Memory | ~1 MB resident |
| Disk I/O | Negligible |
| Network | Minimal (~1 KB per message) |

Performance is optimized with background execution and caching.

## 🔄 Updates & Maintenance

### Check for Updates

```bash
cd /tmp
wget https://github.com/lyafro/openwrt-telegram-notify/archive/refs/heads/main.zip
unzip main.zip
cd openwrt-telegram-notify-main
diff telegram-notify/core.sh /usr/local/sbin/telegram-notify/core.sh
```

### Upgrade

```bash
# Backup current config
cp /etc/config/telegram-notify /etc/config/telegram-notify.bak

# Run installer
bash INSTALL.sh

# Verify
uci show telegram-notify.default
```

## 📖 Documentation

- [OpenWrt Wiki](https://openwrt.org/docs/start)
- [Telegram Bot API](https://core.telegram.org/bots/api)
- [Hotplug Documentation](https://openwrt.org/docs/guide-user/base-system/hotplug)


## 📝 License

This project is released into the **public domain**. You are free to use, modify, and distribute it as you see fit, with no restrictions or attribution required.