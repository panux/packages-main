docker run --rm --name build -v $(realpath .):/build -v $(realpath $2):/out panux/package-builder /build/$1.pkgen /out
