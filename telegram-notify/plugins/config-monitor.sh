#!/bin/sh
set -euf

# Configuration Change Monitoring - OpenWrt Optimized
# Simpler version that doesn't require system logs

. /usr/local/sbin/telegram-notify/core.sh || exit 1

[ "$TELEGRAM_ENABLED" != "1" ] && exit 0

CONFIG_DIR="/etc/config"
BACKUP_DIR="/usr/local/sbin/telegram-notify/config-backup"
HASH_FILE="$BACKUP_DIR/config.hash"

mkdir -p "$BACKUP_DIR"

# Monitor config file changes using MD5
monitor_config_changes() {
    local current_hash previous_hash
    local changed_files=""
    
    # Create combined hash of all config files
    current_hash=$(cat "$CONFIG_DIR"/* 2>/dev/null | md5sum | awk '{print $1}')
    
    # Load previous hash
    if [ ! -f "$HASH_FILE" ]; then
        # First initialization
        echo "$current_hash" > "$HASH_FILE"
        log_msg "info" "Config monitoring initialized"
        return 0
    fi
    
    previous_hash=$(cat "$HASH_FILE")
    
    # If hash differs, configs changed
    if [ "$current_hash" != "$previous_hash" ]; then
        log_msg "info" "Config changes detected"
        
        # Find changed files by comparing individual configs
        for config_file in "$CONFIG_DIR"/*; do
            [ ! -f "$config_file" ] && continue
            
            local filename=$(basename "$config_file")
            local backup_file="$BACKUP_DIR/$filename.bak"
            
            if [ ! -f "$backup_file" ]; then
                # New config file
                changed_files="${changed_files}+$filename "
                cp "$config_file" "$backup_file" 2>/dev/null || true
            elif ! cmp -s "$config_file" "$backup_file"; then
                # Config changed
                changed_files="${changed_files}*$filename "
                cp "$config_file" "$backup_file" 2>/dev/null || true
            fi
        done
        
        if [ -n "$changed_files" ]; then
            local msg="⚙️ <b>Config Modified</b>
<b>Files:</b> <code>$changed_files</code>
<b>Time:</b> $(date '+%Y-%m-%d %H:%M:%S')"
            
            send_message "$msg" "HTML"
            log_msg "info" "Config change detected: $changed_files"
        fi
        
        # Update hash
        echo "$current_hash" > "$HASH_FILE"
    fi
}

case "${1:-monitor}" in
    monitor) monitor_config_changes ;;
    reset)
        rm -f "$HASH_FILE"
        rm -rf "$BACKUP_DIR"
        mkdir -p "$BACKUP_DIR"
        log_msg "info" "Config monitoring reset"
        ;;
    *) monitor_config_changes ;;
esac
