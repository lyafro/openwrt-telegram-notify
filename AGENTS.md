# AGENTS.md - OpenWrt Telegram Notify

## Project Overview
Shell script-based notification system for OpenWrt routers that sends alerts via Telegram Bot API.
- `notify.sh` - Core library with messaging, logging, caching, queueing
- `cron.sh` - Cron job scheduler
- `plugins/` - Notification plugins (sysmon, dhcp, wifi, network, etc.)
- `hotplug/` - Hotplug scripts for automatic event handling
- `config/` - UCI configuration template

---

## Build, Lint, and Test Commands

### Syntax Validation
```bash
# Check syntax of all scripts
sh -n telegram-notify/notify.sh
sh -n telegram-notify/cron.sh
for f in telegram-notify/plugins/*.sh; do sh -n "$f"; done

# Check all at once
find . -name "*.sh" -exec sh -n {} \;
```

### ShellCheck Linting
```bash
# Install shellcheck
apt install shellcheck

# Lint core scripts
shellcheck telegram-notify/notify.sh
shellcheck telegram-notify/cron.sh

# Lint all plugins
shellcheck telegram-notify/plugins/*.sh
shellcheck hotplug/98-telegram-notify

# Lint install script
shellcheck install.sh
```

### Running Tests on Real Hardware or Container
```bash
# Setup Telegram config
uci set telegram-notify.default=telegram-notify
uci set telegram-notify.default.token='BOT_TOKEN'
uci set telegram-notify.default.chat_id='CHAT_ID'
uci set telegram-notify.default.enabled='1'
uci commit telegram-notify

# Test core functionality
/opt/telegram-notify/notify.sh

# Test a specific plugin
/opt/telegram-notify/plugins/sysmon.sh stats
/opt/telegram-notify/plugins/sysmon.sh alert
/opt/telegram-notify/plugins/firmware-check.sh
/opt/telegram-notify/plugins/network-monitor.sh
/opt/telegram-notify/plugins/ssh-monitor.sh

# Test cron scheduler
/opt/telegram-notify/cron.sh sysmon_stats

# Test hotplug simulation
INTERFACE=lan ACTION=ifup SUBSYSTEM=iface /etc/hotplug.d/iface/98-telegram-notify
ACTION=add MACADDR=AA:BB:CC:DD:EE:FF IPADDR=192.168.1.100 SUBSYSTEM=dhcp /etc/hotplug.d/dhcp/98-telegram-notify

# View logs
logread -e telegram-notify
tail /opt/telegram-notify/logs/bot.log
```

### Docker/Podman Testing
```bash
# Build test image
podman build -t openwrt-telegram-test .

# Run container
podman run -dit --name test --network=host --privileged \
  -e TELEGRAM_TOKEN=... -e TELEGRAM_CHAT_ID=... \
  openwrt-telegram-test

# Or run install script directly in container
podman exec test sh -c 'wget -q https://raw.githubusercontent.com/lyafro/openwrt-telegram-notify/main/install.sh -O - | sh'
```

---

## Code Style Guidelines

### Shell Interpreter
- Use `#!/bin/sh` shebang (POSIX-compatible)
- Avoid bashisms (no `[[`, `==`, `$(())` unless needed)
- Avoid `set -f` (breaks glob expansion)

### Error Handling
- Use `set -eu` at script top (avoid `-f` which breaks globs)
- Use `|| return 1` or `|| true` for expected failures
- Redirect stderr: `command 2>/dev/null`

### Variables
- Use `local` for function-scoped variables
- Uppercase for constants: `BOT_DIR`, `LOG_FILE`, `TELEGRAM_TOKEN`
- Lowercase for local vars: `local msg`
- Quote variables: `"$var"` not `$var`
- Defaults: `${var:-default}`

### Functions
- Lowercase with underscores: `load_config()`, `notify()`
- Define before main code
- Return 0 for success, non-zero for failure

### Imports/Sourcing
- Source: `. /opt/telegram-notify/notify.sh`

### Formatting
- Indent with 4 spaces (no tabs)
- Max ~120 chars per line
- Use backslash for line continuation

### Telegram Messages
- HTML parse mode: `<b>bold</b>`, `<i>italic</i>`
- Use `escape_html()` function: `<` → `&lt;`, `&` → `&amp;`
- Emoji sparingly: 🖥️ ⚠️ 📡 ✅ ❌

---

## Configuration

### UCI Config
- Config file: `/etc/config/telegram-notify`
- Use `uci -q get` to avoid errors
- Defaults with `${var:-default}`
- Requires `uci commit` after changes

### Settings
```
config telegram-notify
    option token 'BOT_TOKEN'
    option chat_id 'CHAT_ID'
    option enabled '1'
```

---

## Core API Functions

### notify.sh
```sh
. /opt/telegram-notify/notify.sh

# Send notification (handles queue on failure)
notify "<b>Message</b>" "HTML"

# Cache functions
cache_set "key" "value" 60    # TTL in seconds
cache_get "key"              # Returns value or exits with error
cache_del "key"              # Delete from cache

# Logging
log_msg info "Message"
log_msg error "Failed"
```

---

## Logging
- Use `log_msg` from notify.sh
- Levels: `info`, `warn`, `error`, `debug`
- Logs to: `/opt/telegram-notify/logs/bot.log` and syslog

---

## File Permissions
- Scripts: 755
- Config: 600
- Sensitive dirs (cache, logs, queue): 700

---

## Hotplug Scripts
- Location: `/etc/hotplug.d/iface/`, `/etc/hotplug.d/dhcp/`, `/etc/hotplug.d/net/`
- Environment variables: `$ACTION`, `$INTERFACE`, `$ADDRESS`, `$MACADDR`, `$IPADDR`, `$SUBSYSTEM`
- Run in background: `&`

---

## Common Patterns
```sh
# Check Telegram configured
[ "$TELEGRAM_ENABLED" = "1" ] || return 1
[ -n "$TELEGRAM_TOKEN" ] || return 1
[ -n "$TELEGRAM_CHAT_ID" ] || return 1

# Send notification
notify "<b>Title</b>
<b>Field:</b> value"

# Escape HTML
escaped=$(escape_html "$input")

# Read system file safely
value=$(cat /proc/file 2>/dev/null || echo "N/A")

# Safe iteration
for file in "$dir"/*; do
    [ -f "$file" ] || continue
    # process "$file"
done
```

---

## Project Structure
```
.
├── install.sh              # One-line installer
├── Dockerfile             # For container testing
├── README.md
├── AGENTS.md
├── config/
│   ├── telegram-notify    # UCI config template
│   └── crontab.append    # Cron jobs
├── hotplug/
│   └── 98-telegram-notify # Hotplug handler
└── telegram-notify/
    ├── notify.sh          # Core library
    ├── cron.sh           # Cron scheduler
    └── plugins/
        ├── sysmon.sh
        ├── dhcp-notify.sh
        ├── wifi-notify.sh
        ├── iface-notify.sh
        ├── network-monitor.sh
        ├── ssh-monitor.sh
        ├── firmware-check.sh
        ├── config-monitor.sh
        └── luci-monitor.sh
```

---

## Notes
- Runs on OpenWrt routers with limited resources - keep lightweight
- Test in container before deploying to router
- Use `sh -n` to check syntax before pushing
- Verify manually with test messages
- UCI changes require `uci commit`
- BOT_DIR defaults to `/opt/telegram-notify`
