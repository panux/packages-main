#!/bin/sh

set -e

img="$1"
arch="$2"
sdir="$3"

odir="$PMP/out/$arch"

docker run -it -v "$PMP/$sdir":/src -v "$PMP/$odir":/out -v "$PMP/tools":/tools "$img" /tools/cbuild.sh /src /root /out "$arch"

touch "$4"
