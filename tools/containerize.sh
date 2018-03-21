#!/bin/sh
set -e

# allow using alternate docker socket as specified in the environment
if [ -z "$DOCKERSOCK" ]; then
	DOCKERSOCK=/var/run/docker.sock
fi
# check that the socket exists
if [ ! -e "$DOCKERSOCK" ]; then
	echo Docker socket "($DOCKERSOCK)" does not exist > /dev/stderr
	exit 1
fi
# check that we have docker permission
if [ ! -w "$DOCKERSOCK" ]; then
	if [ -z "$SUDO" ]; then
		SUDO=sudo
	fi
	echo Insufficient permissions on docker socket "($DOCKERSOCK)" > /dev/stderr
	exec $SUDO PARUSER=$(whoami) "$0" "$@"
	exit 1
fi

if [ -z "$DEBUG" ]; then
	DOCKERFLAGS="-q"
else
	echo "Docker Socket: $DOCKERSOCK"
	echo "PMP: $PMP"
fi

docker build $DOCKERFLAGS tools -t panux/packages-main > /dev/null
docker run --rm -it -e PMP="$(pwd)" -v "$(pwd)":/root/packages-main -v /var/run/docker.sock:/var/run/docker.sock panux/packages-main "$@"

if [ ! -z "$PARUSER" ]; then
	echo "Fixing permissions. . ."
	chown -R $PARUSER .
fi
