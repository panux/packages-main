FROM alpine:3.7
RUN apk --no-cache add go git luajit gcc wget make libc-dev docker g++
RUN wget https://github.com/panux/lbuild/archive/v0.1.1.tar.gz -O lbuild.tar.gz &&\
    tar -xf lbuild.tar.gz -C /root &&\
    rm lbuild.tar.gz &&\
    make -C /root/lbuild-* install &&\
    rm -r /root/lbuild-*
RUN wget https://github.com/panux/lpkg/archive/v0.10.7.7.tar.gz -O lpkg.tar.gz &&\
    tar -xf lpkg.tar.gz -C /root &&\
    rm lpkg.tar.gz &&\
    make -C /root/lpkg-* install-local-tools &&\
    rm -r /root/lpkg-*
RUN wget https://github.com/panux/panux-build-tools/archive/v0.1.tar.gz -O panux-build-tools.tar.gz &&\
    tar -xf panux-build-tools.tar.gz -C /root &&\
    rm panux-build-tools.tar.gz &&\
    make -C /root/panux-build-tools-* install &&\
    rm -r /root/panux-build-tools-*
RUN ln -s /bin/busybox /usr/bin/busybox &&\
    ln -s /usr/bin/luajit /bin/luajit
VOLUME /var/run/docker.sock
WORKDIR /root/packages-main
ENV NOCONTAINER true
ENTRYPOINT ["/usr/bin/lbuild"]
