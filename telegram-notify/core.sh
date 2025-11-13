#!/bin/sh
set -euf

BOT_DIR="${BOT_DIR:-/usr/local/sbin/telegram-notify}"
BOT_LOCK="$BOT_DIR/.lock"
CURL_TIMEOUT=10
MAX_LOG_SIZE=$((10 * 1024 * 1024))

load_config() {
    TELEGRAM_TOKEN=$(uci -q get telegram-notify.default.token)
    TELEGRAM_CHAT_ID=$(uci -q get telegram-notify.default.chat_id)
    TELEGRAM_ENABLED=$(uci -q get telegram-notify.default.enabled)
    LOG_FILE="$BOT_DIR/logs/bot.log"

    TELEGRAM_TOKEN="${TELEGRAM_TOKEN:-}"
    TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID:-}"
    TELEGRAM_ENABLED="${TELEGRAM_ENABLED:-0}"

    if [ -z "$TELEGRAM_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ]; then
        return 1
    fi
}

log_msg() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    mkdir -p "$BOT_DIR/logs"
    printf '%s [%s] %s
' "[$timestamp]" "$level" "$message" >> "$LOG_FILE" 2>/dev/null || true

    if [ -f "$LOG_FILE" ]; then
        local size
        size=$(stat -c%s "$LOG_FILE" 2>/dev/null || stat -f%z "$LOG_FILE" 2>/dev/null || echo 0)
        if [ "$size" -gt "$MAX_LOG_SIZE" ]; then
            gzip -c "$LOG_FILE" > "$LOG_FILE.$(date +%s).gz" 2>/dev/null &&             : > "$LOG_FILE" 2>/dev/null || true
        fi
    fi
}

send_message() {
    local text="$1"
    local parse_mode="${2:-HTML}"

    if [ "$TELEGRAM_ENABLED" != "1" ]; then
        log_msg "warn" "Telegram disabled, skip message"
        return 1
    fi

    if [ -z "$TELEGRAM_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ]; then
        log_msg "error" "Token or chat_id not configured"
        return 1
    fi

    local url="https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage"
    local response

    response=$(curl -s --max-time "$CURL_TIMEOUT" --connect-timeout 5         -X POST "$url"         --data-urlencode "chat_id=$TELEGRAM_CHAT_ID"         --data-urlencode "text=$text"         --data-urlencode "parse_mode=$parse_mode" 2>&1 || echo '{"ok":false}')

    if echo "$response" | grep -q '"ok":true'; then
        log_msg "info" "Message sent: $(printf '%.50s' "$text")"
        return 0
    else
        log_msg "error" "Send failed: $response"
        return 1
    fi
}

send_photo() {
    local photo_url="$1"
    local caption="${2:-}"

    if [ "$TELEGRAM_ENABLED" != "1" ]; then
        return 1
    fi

    local url="https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendPhoto"
    curl -s --max-time "$CURL_TIMEOUT"         -X POST "$url"         --data-urlencode "chat_id=$TELEGRAM_CHAT_ID"         --data-urlencode "photo=$photo_url"         --data-urlencode "caption=$caption" >/dev/null 2>&1 || true
}

cache_set() {
    local key="$1"
    local value="$2"
    local ttl="${3:-300}"

    mkdir -p "$BOT_DIR/cache"
    printf '%s
%d
' "$value" "$(($(date +%s) + ttl))" > "$BOT_DIR/cache/$key" 2>/dev/null || true
}

cache_get() {
    local key="$1"
    local cache_file="$BOT_DIR/cache/$key"

    [ -f "$cache_file" ] || return 1

    local expiry
    expiry=$(tail -1 "$cache_file" 2>/dev/null || echo 0)

    if [ "$expiry" -lt "$(date +%s)" ]; then
        rm -f "$cache_file"
        return 1
    fi

    head -1 "$cache_file"
}

cache_del() {
    local key="$1"
    rm -f "$BOT_DIR/cache/$key"
}

acquire_lock() {
    local lockfile="$BOT_LOCK"
    local timeout=30
    local elapsed=0

    while [ -f "$lockfile" ] && [ "$elapsed" -lt "$timeout" ]; do
        sleep 0.1
        elapsed=$((elapsed + 1))
    done

    touch "$lockfile"
}

release_lock() {
    rm -f "$BOT_LOCK"
}

trap 'release_lock' EXIT

load_config
