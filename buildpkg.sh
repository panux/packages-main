docker run --rm --name build -v $(realpath .):/build -v $(realpath $2):/out panux/package-builder:$3 /build/$1.pkgen /out
