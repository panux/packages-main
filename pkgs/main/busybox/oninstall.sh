#!/bin/sh

for i in $($1/usr/bin/busybox --list); do
    lpkg-alt update $i
done
