#!/bin/sh
# OpenWrt Telegram Notify - Core

set -euf

BOT_DIR="/usr/local/sbin/telegram-notify"
LOG_FILE="$BOT_DIR/logs/bot.log"
QUEUE_DIR="$BOT_DIR/queue"
CACHE_DIR="$BOT_DIR/cache"
CURL_TIMEOUT=10
MAX_LOG_SIZE=$((10 * 1024 * 1024))

load_config() {
    TELEGRAM_TOKEN=$(uci -q get telegram-notify.default.token 2>/dev/null)
    TELEGRAM_CHAT_ID=$(uci -q get telegram-notify.default.chat_id 2>/dev/null)
    TELEGRAM_ENABLED=$(uci -q get telegram-notify.default.enabled 2>/dev/null)
    TELEGRAM_TOKEN="${TELEGRAM_TOKEN:-}"
    TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID:-}"
    TELEGRAM_ENABLED="${TELEGRAM_ENABLED:-0}"
}

log_msg() {
    local level="$1"
    shift
    local msg="$*"
    local ts=$(date '+%Y-%m-%d %H:%M:%S')

    mkdir -p "$BOT_DIR/logs"
    printf '%s [%s] %s
' "[$ts]" "$level" "$msg" >> "$LOG_FILE" 2>/dev/null
    logger -t telegram-notify -p "user.$level" "$msg" 2>/dev/null

    if [ -f "$LOG_FILE" ]; then
        local size=$(stat -c%s "$LOG_FILE" 2>/dev/null || echo 0)
        if [ "$size" -gt "$MAX_LOG_SIZE" ]; then
            mv "$LOG_FILE" "$LOG_FILE.1"
            gzip "$LOG_FILE.1" 2>/dev/null || true
            : > "$LOG_FILE"
        fi
    fi
}

send_message() {
    local text="$1"
    local parse_mode="${2:-HTML}"
    local attempt=1

    [ "$TELEGRAM_ENABLED" = "1" ] || return 1
    [ -n "$TELEGRAM_TOKEN" ] || return 1
    [ -n "$TELEGRAM_CHAT_ID" ] || return 1

    while [ $attempt -le 3 ]; do
        local response=$(curl -s --max-time "$CURL_TIMEOUT" --connect-timeout 5             -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage"             --data-urlencode "chat_id=$TELEGRAM_CHAT_ID"             --data-urlencode "text=$text"             --data-urlencode "parse_mode=$parse_mode" 2>&1)

        if echo "$response" | grep -q '"ok":true'; then
            log_msg info "Message sent"
            return 0
        fi

        if [ $attempt -lt 3 ]; then
            sleep $((attempt * 2))
        fi

        attempt=$((attempt + 1))
    done

    log_msg error "Send failed, queuing"
    queue_message "$text"
    return 1
}

queue_message() {
    local msg="$1"
    mkdir -p "$QUEUE_DIR"
    echo "$msg" > "$QUEUE_DIR/$(date +%s)_$$.msg" 2>/dev/null
}

process_queue() {
    [ ! -d "$QUEUE_DIR" ] && return 0

    local count=0
    for msg_file in "$QUEUE_DIR"/*.msg; do
        [ ! -f "$msg_file" ] && continue

        local msg=$(cat "$msg_file" 2>/dev/null)
        if send_message "$msg" "HTML"; then
            rm -f "$msg_file"
            count=$((count + 1))
            sleep 1
        fi
    done
}

cache_set() {
    local key="$1"
    local value="$2"
    local ttl="${3:-300}"
    mkdir -p "$CACHE_DIR"

    local expire=$(($(date +%s) + ttl))
    echo "$value" > "$CACHE_DIR/$key"
    echo "$expire" >> "$CACHE_DIR/$key"
}

cache_get() {
    local key="$1"
    local file="$CACHE_DIR/$key"

    if [ ! -f "$file" ]; then
        return 1
    fi

    local expiry=$(tail -n 1 "$file")
    local now=$(date +%s)

    if [ "$expiry" -lt "$now" ]; then
        rm -f "$file"
        return 1
    fi

    head -n 1 "$file"
}

cache_del() {
    rm -f "$CACHE_DIR/$1" 2>/dev/null
}

load_config
