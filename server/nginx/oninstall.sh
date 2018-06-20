#!/usr/bin/busybox sh

if [ "$1" == install ]; then
    chroot $2 adduser -D nobody
fi
