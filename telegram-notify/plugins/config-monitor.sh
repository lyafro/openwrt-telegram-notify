#!/bin/sh
set -euf
. /opt/telegram-notify/notify.sh

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

[ -n "$CHANGED" ] && notify "⚙️ <b>Config Modified</b>
<b>Files:</b> <code>$CHANGED</code>"
