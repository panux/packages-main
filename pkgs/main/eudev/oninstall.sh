#!/usr/bin/sh

if [ "$1" != install ]; then
  exit 0
fi

if [ ! -e "$2/etc/group" ]; then
  touch "$2/etc/group"
fi

for g in tty dialout kmem input video audio lp disk cdrom tape; do
  chroot "$2" addgroup -S $g;
done
