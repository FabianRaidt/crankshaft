FROM --platform=linux/i386 debian:buster

ENV DEBIAN_FRONTEND=noninteractive

# Use Debian archive repository for oldoldstable (buster)
RUN echo "deb http://archive.debian.org/debian/ buster main" > /etc/apt/sources.list && \
    echo "deb http://archive.debian.org/debian-security buster/updates main" >> /etc/apt/sources.list && \
    echo "Acquire::Check-Valid-Until false;" > /etc/apt/apt.conf.d/99no-check-valid-until

RUN apt-get -y update && \
    apt-get -y install \
        git vim parted \
        quilt coreutils qemu-user-static debootstrap zerofree zip dosfstools \
        bsdtar libcap2-bin rsync grep udev xz-utils curl xxd file kmod bc\
    && rm -rf /var/lib/apt/lists/*

COPY . /pi-gen/

VOLUME [ "/pi-gen/work", "/pi-gen/deploy"]
