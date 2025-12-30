#!/bin/bash -e

# Ensure QEMU is present for ARM64 chroot
if [ -x /usr/bin/qemu-aarch64-static ]; then
	install -m 0755 /usr/bin/qemu-aarch64-static "${ROOTFS_DIR}/usr/bin/"
fi

install -m 644 files/sources.list "${ROOTFS_DIR}/etc/apt/"
install -m 644 files/99force-confold "${ROOTFS_DIR}/etc/apt/apt.conf.d/"

if [ -n "$APT_PROXY" ]; then
	install -m 644 files/51cache "${ROOTFS_DIR}/etc/apt/apt.conf.d/51cache"
	sed "${ROOTFS_DIR}/etc/apt/apt.conf.d/51cache" -i -e "s|APT_PROXY|${APT_PROXY}|"
else
	rm -f "${ROOTFS_DIR}/etc/apt/apt.conf.d/51cache"
fi

# Convert GPG key to binary format and install it
mkdir -p "${ROOTFS_DIR}/usr/share/keyrings"
gpg --dearmor < files/raspberrypi.gpg.key > "${ROOTFS_DIR}/usr/share/keyrings/raspberrypi.gpg"

# Now install raspi.list with the signed-by directive
install -m 644 files/raspi.list "${ROOTFS_DIR}/etc/apt/sources.list.d/"

on_chroot << EOF
apt-get update
apt-get install -y gnupg
apt-get dist-upgrade -y
EOF
