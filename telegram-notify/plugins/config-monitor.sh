#!/bin/sh
set -euf
. /usr/local/sbin/telegram-notify/core.sh || exit 1
[ "$TELEGRAM_ENABLED" != "1" ] && exit 0

backup_dir="/usr/local/sbin/telegram-notify/config-backup"
mkdir -p "$backup_dir"

changed=""
for cfg in /etc/config/*; do
    [ ! -f "$cfg" ] && continue
    name=$(basename "$cfg")
    bak="$backup_dir/$name.bak"

    if [ ! -f "$bak" ]; then
        changed="${changed}+$name "
        cp "$cfg" "$bak" 2>/dev/null || true
    elif ! cmp -s "$cfg" "$bak" 2>/dev/null; then
        changed="${changed}*$name "
        cp "$cfg" "$bak" 2>/dev/null || true
    fi
done

[ -n "$changed" ] && send_message "⚙️ <b>Config Modified</b>
<b>Files:</b> <code>$changed</code>" "HTML"
