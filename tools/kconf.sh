#!/bin/sh

docker pull panux/menuconf-docker

docker run -it --rm -v $(realpath pkgs/kernel/linux/conf):/kernel panux/menuconf-docker 4.13.10 /kernel/$1.conf $1
