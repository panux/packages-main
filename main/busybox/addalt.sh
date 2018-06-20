for i in $(out/busybox/usr/bin/busybox --list); do
    mkdir out/busybox/etc/lpkg.d/alt.d/$i || exit 1
    ln -s /usr/bin/busybox out/busybox/etc/lpkg.d/alt.d/$i/01_busybox.provider || exit 1
    echo /usr/bin/$i > out/busybox/etc/lpkg.d/alt.d/$i/.target || exit 1
done
