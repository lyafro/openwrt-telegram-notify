#!/bin/sh
set -euf
. /opt/telegram-notify/notify.sh

case "${1:-all}" in
    sysmon_alert)
        /opt/telegram-notify/plugins/sysmon.sh alert
        ;;
    sysmon_stats)
        /opt/telegram-notify/plugins/sysmon.sh stats
        ;;
    firmware)
        /opt/telegram-notify/plugins/firmware-check.sh
        ;;
    network)
        /opt/telegram-notify/plugins/network-monitor.sh
        ;;
    ssh)
        /opt/telegram-notify/plugins/ssh-monitor.sh
        ;;
    config)
        /opt/telegram-notify/plugins/config-monitor.sh
        ;;
    all)
        /opt/telegram-notify/plugins/sysmon.sh alert
        /opt/telegram-notify/plugins/ssh-monitor.sh
        /opt/telegram-notify/plugins/config-monitor.sh
        ;;
esac
