#!/bin/bash

set -x

echo "Making packages. . . "
make $@

echo "Making output dir"
make -C out

echo "Starting container and installing packages"
docker run --rm -it -v $(pwd)/out/out:/pkgs panux/panux:x86_64 -c 'for i in $@; do lpkg-inst /pkgs/$i.tar.gz; done; sh' -- $@
