#!/bin/sh

cmd="$1"
rootfs="$2"

alt() {
    if [ -z "$bootstrap" ]; then
        lpkg-alt update "$1"
    else
        sh "$bootstrap/alternative.sh" update "$1"
    fi
}

for i in $(busybox --list); do
    alt $i
done
