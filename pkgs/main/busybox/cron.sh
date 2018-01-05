#!/etc/rc.common

depends() {
    dep linit-supd
}

start() {
    linit-sup --name cron --log /var/log/cron.log -- /bin/crond -f
}

stop() {
    linit-sup-stop 3 cron
}
