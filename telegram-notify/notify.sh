#!/bin/sh
set -euf

BOT_DIR="${BOT_DIR:-/opt/telegram-notify}"
LOG_FILE="$BOT_DIR/logs/bot.log"
QUEUE_DIR="$BOT_DIR/queue"
CACHE_DIR="$BOT_DIR/cache"
CURL_TIMEOUT=10
MAX_LOG_SIZE=10485760

load_config() {
    TELEGRAM_TOKEN="$(uci -q get telegram-notify.default.token 2>/dev/null)"
    TELEGRAM_CHAT_ID="$(uci -q get telegram-notify.default.chat_id 2>/dev/null)"
    TELEGRAM_ENABLED="$(uci -q get telegram-notify.default.enabled 2>/dev/null)"
    TELEGRAM_TOKEN="${TELEGRAM_TOKEN:-}"
    TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID:-}"
    TELEGRAM_ENABLED="${TELEGRAM_ENABLED:-0}"
}

escape_html() {
    printf '%s' "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'
}

log_msg() {
    local level="$1"
    shift
    local msg="$*"
    local ts="$(date '+%Y-%m-%d %H:%M:%S')"

    mkdir -p "$BOT_DIR/logs"
    printf '%s [%s] %s\n' "[$ts]" "$level" "$msg" >> "$LOG_FILE" 2>/dev/null || true
    logger -t telegram-notify -p "user.$level" "$msg" 2>/dev/null || true

    if [ -f "$LOG_FILE" ]; then
        local size
        size="$(stat -c%s "$LOG_FILE" 2>/dev/null)" || size=0
        if [ "$size" -gt "$MAX_LOG_SIZE" ]; then
            mv "$LOG_FILE" "$LOG_FILE.1"
            gzip "$LOG_FILE.1" 2>/dev/null || true
            : > "$LOG_FILE"
        fi
    fi
}

queue_message() {
    local msg="$1"
    local tmp
    mkdir -p "$QUEUE_DIR"
    tmp="$(mktemp "$QUEUE_DIR"/msg_XXXXXX 2>/dev/null)" || return 1
    printf '%s' "$msg" > "$tmp" 2>/dev/null || true
}

process_queue() {
    [ -d "$QUEUE_DIR" ] || return 0

    for msg_file in "$QUEUE_DIR"/msg_*; do
        [ -f "$msg_file" ] || continue

        local msg
        msg="$(cat "$msg_file" 2>/dev/null)" || continue
        if _notify "$msg" "HTML"; then
            rm -f "$msg_file"
            sleep 1
        fi
    done
}

cache_set() {
    local key="$1"
    local value="$2"
    local ttl="${3:-300}"
    mkdir -p "$CACHE_DIR"

    local expire
    expire="$(($(date +%s) + ttl))"
    printf '%s\n%s\n' "$value" "$expire" > "$CACHE_DIR/$key" 2>/dev/null || true
}

cache_get() {
    local key="$1"
    local file="$CACHE_DIR/$key"

    [ -f "$file" ] || return 1

    local expiry now
    expiry="$(tail -n 1 "$file" 2>/dev/null)" || return 1
    now="$(date +%s)"

    [ "$expiry" -lt "$now" ] && { rm -f "$file"; return 1; }

    head -n 1 "$file"
}

cache_del() {
    rm -f "$CACHE_DIR/$1" 2>/dev/null || true
}

_notify() {
    local text="$1"
    local parse_mode="${2:-HTML}"
    local attempt=1

    while [ $attempt -le 3 ]; do
        local response
        response="$(curl -s --max-time "$CURL_TIMEOUT" --connect-timeout 5 \
            # --resolve "api.telegram.org:443:149.154.167.220" \
            -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
            --data-urlencode "chat_id=$TELEGRAM_CHAT_ID" \
            --data-urlencode "text=$text" \
            --data-urlencode "parse_mode=$parse_mode" 2>&1)" || true

        if echo "$response" | grep -q '"ok":true'; then
            log_msg info "Message sent"
            return 0
        fi

        [ $attempt -lt 3 ] && sleep $((attempt * 2))
        attempt=$((attempt + 1))
    done

    log_msg error "Send failed"
    return 1
}

notify() {
    [ "$TELEGRAM_ENABLED" = "1" ] || return 1
    [ -n "$TELEGRAM_TOKEN" ] || return 1
    [ -n "$TELEGRAM_CHAT_ID" ] || return 1

    if _notify "$1" "${2:-HTML}"; then
        return 0
    fi

    queue_message "$1"
    return 1
}

load_config
