docker run -it --rm --name build -v $(realpath .):/build -v $(realpath out):$(realpath $2) panux/package-builder /build/$1.pkgen /out || exit 1
