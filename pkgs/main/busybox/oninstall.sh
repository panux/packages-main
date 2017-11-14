#!/bin/sh

echo busybox $1 $2

for i in $($2/usr/bin/busybox --list); do
    lpkg-alt update $i
done
