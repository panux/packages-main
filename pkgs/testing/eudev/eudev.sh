#!/etc/rc.common

start() {
    udevd --daemon
}

stop() {
    udevadm control --exit
}

enable() {
    /etc/init.d/pre enable
    ln -s /etc/init.d/$this /etc/rc.d/pre/$this
}

disable() {
    rm /etc/rc.d/pre/$this
}
