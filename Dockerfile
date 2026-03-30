FROM docker.io/openwrt/rootfs:x86-64-24.10.5

RUN mkdir -p /var/lock /opt/telegram-notify/{plugins,logs,cache,queue,config-backup} /etc/hotplug.d/{iface,dhcp}

COPY telegram-notify/notify.sh /opt/telegram-notify/
COPY telegram-notify/cron.sh /opt/telegram-notify/
COPY telegram-notify/plugins/*.sh /opt/telegram-notify/plugins/
COPY hotplug/98-telegram-notify /etc/hotplug.d/iface/

RUN chmod 755 /opt/telegram-notify/notify.sh /opt/telegram-notify/cron.sh /opt/telegram-notify/plugins/*.sh /etc/hotplug.d/iface/98-telegram-notify

ENV BOT_DIR=/opt/telegram-notify
ENV CURL_TIMEOUT=10

# Set at runtime:
# docker run -e TELEGRAM_TOKEN=... -e TELEGRAM_CHAT_ID=... -e TELEGRAM_ENABLED=1 ...

CMD ["/bin/sh"]
