# AGENTS.md - OpenWrt Telegram Notify

## Project Overview
Shell script-based notification system for OpenWrt routers that sends alerts via Telegram Bot API. Components:
- `core.sh` - Core library with messaging, logging, caching, queueing
- `plugins/` - Notification plugins (sysmon, dhcp, wifi, network, etc.)
- `hotplug/` - Hotplug scripts for automatic event handling
- `config/` - UCI configuration template

---

## Build, Lint, and Test Commands

### Running Tests (manual, no formal test framework)
```bash
# Test core functionality
/opt/telegram-notify/core.sh

# Test a specific plugin
/opt/telegram-notify/plugins/sysmon.sh stats

# Test sending a message (requires configured token/chat_id)
send_message "Test message" "HTML"

# Test configuration
uci show telegram-notify
```

### Linting with shellcheck
```bash
# Install shellcheck
apt install shellcheck

# Lint scripts
shellcheck telegram-notify/core.sh
shellcheck telegram-notify/plugins/*.sh
shellcheck telegram-notify/**/*.sh
```

### Code Validation
- Syntax check: `sh -n script.sh`
- Check permissions: `ls -la telegram-notify/plugins/`
- Validate UCI: `uci validate telegram-notify`

---

## Code Style Guidelines

### Shell Interpreter
- Use `#!/bin/sh` shebang (POSIX-compatible)
- Avoid bashisms

### Error Handling
- Always use `set -euf` at script top
- Use `|| return 1` or `|| true` for expected failures
- Redirect stderr: `command 2>/dev/null`

### Variables
- Use `local` for function-scoped variables
- Uppercase for constants: `BOT_DIR`, `LOG_FILE`
- Lowercase for local vars: `local msg`
- Quote variables: `"$var"` not `$var`
- Defaults: `${var:-default}`

### Functions
- Lowercase with underscores: `load_config()`, `send_message()`
- Define before main code
- Return 0 for success, non-zero for failure

### Naming Conventions
- Scripts: `lowercase-with-dashes.sh`
- Variables: `lowercase` or `UPPERCASE` for constants

### Imports/Sourcing
- Source: `. /opt/telegram-notify/core.sh`

### Formatting
- Indent with 4 spaces (no tabs)
- Max ~120 chars per line
- Use backslash for continuation

### Telegram Messages
- HTML parse mode: `<b>bold</b>`, `<i>italic</i>`
- Escape: `<` → `&lt;`, `&` → `&amp;`
- Emoji sparingly: 🖥️ ⚠️ 📡 ✅ ❌

### Configuration
- UCI: `/etc/config/telegram-notify`
- Use `uci -q get` to avoid errors
- Defaults with `${var:-default}`

### Logging
- Use `log_msg` from core.sh
- Levels: `info`, `warn`, `error`, `debug`
- Log to file and syslog: `logger -t telegram-notify`

### Caching
- Use `cache_set`, `cache_get`, `cache_del` from core.sh
- TTL in seconds (default 300)

### Queueing
- Use `queue_message()` for failed sends
- Process with `process_queue()` on startup
- Add delays: `sleep 1`

### API Calls
- Curl with timeout: `--max-time 10 --connect-timeout 5`
- Retry: 3 attempts with exponential backoff
- Parse JSON: `echo "$response" | grep -q '"ok":true'`

### File Permissions
- Scripts: 755, Config: 600, Sensitive dirs: 700

### Hotplug Scripts
- Place in `/etc/hotplug.d/` subdirectories
- Exit early if disabled: `[ "$TELEGRAM_ENABLED" = "1" ] || exit 0`

---

## Common Patterns

```sh
# Check Telegram configured
[ "$TELEGRAM_ENABLED" = "1" ] || return 1
[ -n "$TELEGRAM_TOKEN" ] || return 1
[ -n "$TELEGRAM_CHAT_ID" ] || return 1

# Send notification
send_message "<b>Title</b>
<b>Field:</b> value" "HTML"

# Read system file safely
value=$(cat /proc/file 2>/dev/null || echo "N/A")

# Iterate safely
for file in "$dir"/*; do
    [ -f "$file" ] || continue
    # process "$file"
done
```

---

## Project Structure
```
.
├── AGENTS.md, INSTALL.sh, README.md
├── config/telegram-notify, crontab.append
├── hotplug/dhcp/98-telegram-notify, hostapd/98-telegram-notify, iface/98-telegram-notify
└── telegram-notify/core.sh + plugins/*.sh
```

---

## Notes
- Runs on OpenWrt routers with limited resources - keep lightweight
- Test on dev machine before deploying
- Use `sh -n` to check syntax before uploading
- No formal test suite - verify manually
- UCI changes require `uci commit`
