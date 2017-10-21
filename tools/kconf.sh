#!/bin/sh

docker pull panux/menuconf-docker

docker run -it --rm -v $(realpath pkgs/kernel/linux):/kernel/conf panux/menuconf-docker 4.9.35 /kernel/kernel-$1.conf $1
