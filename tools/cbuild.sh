#!/bin/sh

set -e

# Script to be run in container to build the thing
sdir="$1"
bdir="$2"
odir="$3"
arch="$4"

# copy makefile into build directory
cp "$sdir/build-$arch.mk" "$bdir/Makefile"

# run build
make -j6 -C "$bdir" SRCTAR="$sdir/src.tar" || sh

# copy tars to output dir
for t in $(ls "$bdir/tars"); do
    cp "$bdir/tars/$t" "$odir/$t"
done
