#!/bin/sh

docker run --rm -it -v $PWD/build/busybox/src:/src --entrypoint /bin/sh panux/buildenv:busybox-$1 -c "/scripts/install.sh ncurses-dev && tar -xf /src/busybox-1.27.2.tar.bz2 && mv busybox-1.27.2 busybox && cp /src/conf/$1.conf busybox/.config && make -C busybox menuconfig && mv -f busybox/.config /src/conf/$1.conf" || exit 1

mv -f build/busybox/src/conf/$1.conf pkgs/main/busybox/conf/$1.conf || exit 1

rm -r build/busybox/src || exit 1

echo "Done!"
