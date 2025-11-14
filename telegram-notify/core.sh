#!/bin/sh
# OpenWrt Telegram Notify - Core Engine
# Supports: OpenWrt 19.07+, 21.02+, 22.03+, 23.05+, 24.10+

set -euf

BOT_DIR="${BOT_DIR:-/usr/local/sbin/telegram-notify}"
LOG_FILE="$BOT_DIR/logs/bot.log"
QUEUE_DIR="$BOT_DIR/queue"
CACHE_DIR="$BOT_DIR/cache"
CURL_TIMEOUT=10
MAX_LOG_SIZE=$((10 * 1024 * 1024))

# Load configuration from UCI
load_config() {
    TELEGRAM_TOKEN=$(uci -q get telegram-notify.default.token 2>/dev/null || echo "")
    TELEGRAM_CHAT_ID=$(uci -q get telegram-notify.default.chat_id 2>/dev/null || echo "")
    TELEGRAM_ENABLED=$(uci -q get telegram-notify.default.enabled 2>/dev/null || echo "0")
}

# Logging with rotation
log_msg() {
    local level="$1"
    shift
    local msg="$*"
    local ts=$(date '+%Y-%m-%d %H:%M:%S')

    mkdir -p "$BOT_DIR/logs"
    printf '%s [%s] %s
' "[$ts]" "$level" "$msg" >> "$LOG_FILE" 2>/dev/null || true

    # Also send to syslog
    logger -t telegram-notify -p "user.$level" "$msg" 2>/dev/null || true

    # Log rotation
    if [ -f "$LOG_FILE" ]; then
        local size=$(stat -c%s "$LOG_FILE" 2>/dev/null || stat -f%z "$LOG_FILE" 2>/dev/null || echo 0)
        if [ "$size" -gt "$MAX_LOG_SIZE" ]; then
            gzip "$LOG_FILE" && mv "$LOG_FILE".gz "$LOG_FILE.$(date +%s).gz" 2>/dev/null || true
            : > "$LOG_FILE"
        fi
    fi
}

# Send message with retry logic
send_message() {
    local text="$1" parse_mode="${2:-HTML}"
    local attempt=1 wait=1

    [ "$TELEGRAM_ENABLED" = "1" ] || return 1
    [ -n "$TELEGRAM_TOKEN" ] || { log_msg error "Token not set"; return 1; }
    [ -n "$TELEGRAM_CHAT_ID" ] || { log_msg error "Chat ID not set"; return 1; }

    while [ $attempt -le 3 ]; do
        local response
        response=$(curl -s --max-time "$CURL_TIMEOUT" --connect-timeout 5             -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage"             --data-urlencode "chat_id=$TELEGRAM_CHAT_ID"             --data-urlencode "text=$text"             --data-urlencode "parse_mode=$parse_mode" 2>&1)

        if echo "$response" | grep -q '"ok":true'; then
            log_msg info "Message sent (attempt $attempt)"
            return 0
        fi

        [ $attempt -lt 3 ] && sleep "$wait" && wait=$((wait * 2))
        attempt=$((attempt + 1))
    done

    log_msg error "Send failed, queuing message"
    queue_message "$text"
    return 1
}

# Queue message for later delivery
queue_message() {
    local msg="$1"
    mkdir -p "$QUEUE_DIR"
    echo "$msg" > "$QUEUE_DIR/$(date +%s)_$$.msg" 2>/dev/null || true
    log_msg info "Message queued"
}

# Process offline queue
process_queue() {
    [ -d "$QUEUE_DIR" ] || return 0

    local count=0
    for msg_file in "$QUEUE_DIR"/*.msg 2>/dev/null; do
        [ -f "$msg_file" ] || continue

        local msg=$(cat "$msg_file" 2>/dev/null)
        [ -z "$msg" ] && { rm -f "$msg_file"; continue; }

        if send_message "$msg" "HTML"; then
            rm -f "$msg_file"
            count=$((count + 1))
            sleep 1
        fi
    done

    [ $count -gt 0 ] && log_msg info "Processed $count queued messages"
}

# Cache operations with TTL
cache_set() {
    local key="$1" value="$2" ttl="${3:-300}"
    mkdir -p "$CACHE_DIR"
    echo "$value" > "$CACHE_DIR/$key" 2>/dev/null || true
    echo "$(($(date +%s) + ttl))" >> "$CACHE_DIR/$key" 2>/dev/null || true
}

cache_get() {
    local key="$1" file="$CACHE_DIR/$key"
    [ -f "$file" ] || return 1
    local expiry=$(tail -1 "$file" 2>/dev/null || echo 0)
    [ "$expiry" -ge "$(date +%s)" ] || { rm -f "$file"; return 1; }
    head -1 "$file"
}

cache_del() {
    rm -f "$CACHE_DIR/$1" 2>/dev/null || true
}

# Main
load_config
