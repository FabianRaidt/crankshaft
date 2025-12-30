FROM debian:bookworm

ENV DEBIAN_FRONTEND=noninteractive

RUN rm -f /etc/apt/sources.list.d/debian.sources && \
    echo "deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware" > /etc/apt/sources.list && \
    echo "deb http://deb.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware" >> /etc/apt/sources.list && \
    echo "deb http://deb.debian.org/debian bookworm-updates main contrib non-free non-free-firmware" >> /etc/apt/sources.list && \
    echo "deb http://deb.debian.org/debian bookworm-backports main contrib non-free non-free-firmware" >> /etc/apt/sources.list

RUN apt-get update && \
    apt-get install -y -t bookworm-backports qemu-user-static udev && \
    apt-get install -y \
    git vim parted quilt coreutils \
    debootstrap zerofree zip dosfstools \
    libarchive-tools libcap2-bin rsync grep \
    xz-utils curl xxd file kmod bc \
    && rm -rf /var/lib/apt/lists/*

# Copy project files into image
COPY . /pi-gen/

WORKDIR /pi-gen

VOLUME ["/pi-gen/work", "/pi-gen/deploy"]
