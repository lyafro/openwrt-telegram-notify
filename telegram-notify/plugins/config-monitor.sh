#!/bin/sh
set -euf
. /usr/local/sbin/telegram-notify/core.sh

[ "$TELEGRAM_ENABLED" = "1" ] || exit 0

BACKUP_DIR="/usr/local/sbin/telegram-notify/config-backup"
mkdir -p "$BACKUP_DIR"

CHANGED=""
for cfg in /etc/config/*; do
    [ ! -f "$cfg" ] && continue

    name=$(basename "$cfg")
    bak="$BACKUP_DIR/$name.bak"

    if [ ! -f "$bak" ] || ! cmp -s "$cfg" "$bak" 2>/dev/null; then
        CHANGED="${CHANGED}$([ -f "$bak" ] && echo "*" || echo "+")$name "
        cp "$cfg" "$bak" 2>/dev/null || true
    fi
done

[ -n "$CHANGED" ] && send_message "⚙️ <b>Config Modified</b>
<b>Files:</b> <code>$CHANGED</code>" "HTML"
