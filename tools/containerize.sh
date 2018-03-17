#!/bin/sh
set -e

docker build tools -t panux/packages-main
exec docker run --rm -it -e PMP=$(pwd) -v $(pwd):/root/packages-main -v /var/run/docker.sock:/var/run/docker.sock panux/packages-main "$@"
