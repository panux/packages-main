#!/bin/sh
set -e

docker build tools -t panux/packages-main
docker run --rm -it -v $(pwd):/root/packages-main panux/packages-main "$@"
