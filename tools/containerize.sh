#!/bin/sh
set -e

docker build -q tools -t panux/packages-main > /dev/null
exec docker run --rm -it -e PMP="$(pwd)" -v "$(pwd)":/root/packages-main -v /var/run/docker.sock:/var/run/docker.sock panux/packages-main "$@"
