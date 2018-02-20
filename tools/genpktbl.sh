#!/bin/busybox sh
set -e

for i in $(busybox find pkgs -name "pkgen.yaml"); do
    for j in $(pkgen -i $i pkgs); do
        busybox printf "%s=%s\n" $j $i
    done
    busybox printf "%s=%s\n" $(basename $(dirname $i)) $i
done > pkgens.list
