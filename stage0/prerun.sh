#!/bin/bash -e

if [ ! -d "${ROOTFS_DIR}" ]; then
    bootstrap bookworm "${ROOTFS_DIR}" http://deb.debian.org/debian/
fi

# QEMU binary is now copied inside the bootstrap function in scripts/common

