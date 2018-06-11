#!/usr/bin/sh

echo busybox $1 $2
chmod 6755 $2/usr/bin/busybox
for i in $($2/usr/bin/busybox --list); do
    lpkg-alt update $i
done
