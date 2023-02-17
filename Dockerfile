FROM alpine:3

RUN apk update \
 && apk upgrade \
 && apk add bash busybox-extras \
 qemu-system-x86_64 qemu-system-i386 qemu-img  \
 qemu-audio-spice qemu-chardev-spice qemu-ui-spice-app qemu-ui-spice-core \
 && rm -vrf /var/cache/apk/*

COPY /src/root/ /root/
COPY /src/etc/profile /etc/
COPY /src/etc/bash.bashrc /etc/
COPY /src/usr/ /usr/

RUN mkdir -p /opt/floppies \
 && mkdir -p /opt/external-mount
COPY /src/opt/floppies/ /opt/floppies/

ENV SHELL=/bin/bash
WORKDIR /root
