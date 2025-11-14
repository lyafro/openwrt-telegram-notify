#!/bin/sh
set -euf
. /usr/local/sbin/telegram-notify/core.sh

[ "$TELEGRAM_ENABLED" = "1" ] || exit 0

BACKUP_DIR="$BOT_DIR/config-backup"
mkdir -p "$BACKUP_DIR"

CHANGED=""
for cfg in /etc/config/*; do
    [ ! -f "$cfg" ] && continue

    name=$(basename "$cfg")
    bak="$BACKUP_DIR/$name.bak"

    if [ ! -f "$bak" ]; then
        CHANGED="$CHANGED +$name"
        cp "$cfg" "$bak"
    elif ! cmp -s "$cfg" "$bak" 2>/dev/null; then
        CHANGED="$CHANGED *$name"
        cp "$cfg" "$bak"
    fi
done

if [ -n "$CHANGED" ]; then
    send_message "⚙️ <b>Config Modified</b>
<b>Files:</b> <code>$CHANGED</code>" "HTML"
fi
