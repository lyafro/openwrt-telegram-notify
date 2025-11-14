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
}

log_msg() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    mkdir -p "$BOT_DIR/logs"
    printf '%s [%s] %s
' "[$timestamp]" "$level" "$message" >> "$LOG_FILE" 2>/dev/null || true

    logger -t "telegram-notify" -p "user.${level}" "$message" 2>/dev/null || true

    if [ -f "$LOG_FILE" ]; then
        local size=$(stat -c%s "$LOG_FILE" 2>/dev/null || stat -f%z "$LOG_FILE" 2>/dev/null || echo 0)
        if [ "$size" -gt "$MAX_LOG_SIZE" ]; then
            gzip -c "$LOG_FILE" > "$LOG_FILE.$(date +%s).gz" 2>/dev/null &&             : > "$LOG_FILE" 2>/dev/null || true
        fi
    fi
}

send_message_with_retry() {
    local text="$1"
    local parse_mode="${2:-HTML}"
    local attempt=1
    local backoff=1

    if [ "$TELEGRAM_ENABLED" != "1" ]; then
        return 1
    fi

    if [ -z "$TELEGRAM_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ]; then
        log_msg "error" "Token or chat_id not configured"
        return 1
    fi

    while [ $attempt -le 3 ]; do
        local url="https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage"
        local response

        response=$(curl -s -w "
%{http_code}" --max-time "$CURL_TIMEOUT" --connect-timeout 5             -X POST "$url"             --data-urlencode "chat_id=$TELEGRAM_CHAT_ID"             --data-urlencode "text=$text"             --data-urlencode "parse_mode=$parse_mode" 2>&1 || echo '{"ok":false}
000')

        local http_code=$(echo "$response" | tail -1)

        if [ "$http_code" = "200" ]; then
            log_msg "info" "Message sent (attempt $attempt)"
            return 0
        elif [ "$http_code" = "429" ]; then
            log_msg "warn" "Rate limited (429). Waiting ${backoff}s..."
            sleep "$backoff"
            backoff=$((backoff * 2))
            attempt=$((attempt + 1))
        else
            log_msg "warn" "Send failed HTTP $http_code (attempt $attempt), retry in ${backoff}s"
            sleep "$backoff"
            backoff=$((backoff * 2))
            attempt=$((attempt + 1))
        fi
    done

    log_msg "error" "Failed after 3 attempts, queuing"
    queue_message "$text"
    return 1
}

send_message() {
    send_message_with_retry "$@"
}

queue_message() {
    local msg="$1"
    mkdir -p "$BOT_DIR/queue"
    echo "$msg" > "$BOT_DIR/queue/$(date +%s)_$$.msg" 2>/dev/null || true
    log_msg "info" "Message queued"
}

process_queue() {
    [ ! -d "$BOT_DIR/queue" ] && return 0

    local count=0
    for msg_file in "$BOT_DIR/queue"/*.msg 2>/dev/null; do
        [ ! -f "$msg_file" ] && continue

        local msg=$(cat "$msg_file")
        if send_message_with_retry "$msg" "HTML"; then
            rm -f "$msg_file"
            count=$((count + 1))
            sleep 1
        fi
    done

    [ $count -gt 0 ] && log_msg "info" "Processed $count queued messages"
}

check_dependencies() {
    local missing=""
    for cmd in curl grep awk sed logger; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing="$missing $cmd"
        fi
    done

    if [ -n "$missing" ]; then
        echo "ERROR: Missing commands:$missing" >&2
        return 1
    fi
    return 0
}

cache_set() {
    local key="$1" value="$2" ttl="${3:-300}"
    mkdir -p "$BOT_DIR/cache"
    printf '%s
%d
' "$value" "$(($(date +%s) + ttl))" > "$BOT_DIR/cache/$key" 2>/dev/null || true
}

cache_get() {
    local key="$1" cache_file="$BOT_DIR/cache/$key"
    [ -f "$cache_file" ] || return 1
    local expiry=$(tail -1 "$cache_file" 2>/dev/null || echo 0)
    if [ "$expiry" -lt "$(date +%s)" ]; then
        rm -f "$cache_file"
        return 1
    fi
    head -1 "$cache_file"
}

cache_del() {
    rm -f "$BOT_DIR/cache/$1"
}

load_config
check_dependencies || exit 1
