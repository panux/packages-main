#!/bin/sh

set -e

img="$1"
arch="$2"
sdir="$3"

odir="$PWD/out/$arch"

docker run -it -v $(realpath $sdir):/src -v $(realpath $odir):/out -v $(realpath tools):/tools "$img" /tools/cbuild.sh /src /root /out "$arch"

touch "$4"
