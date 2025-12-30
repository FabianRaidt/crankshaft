#!/bin/bash -e

# Download and install Pi 5 kernel from latest Raspberry Pi OS
# This ensures we have kernel 6.6+ with Pi 5 support

KERNEL_TEMP="${STAGE_WORK_DIR}/pi5-kernel"
mkdir -p "${KERNEL_TEMP}"

echo "Downloading latest Raspberry Pi kernel with Pi 5 support..."

# Download kernel files directly from Raspberry Pi GitHub firmware repo
# This has the latest Pi 5-compatible kernels
cd "${KERNEL_TEMP}"

# Download entire firmware package for complete Pi 5 support
echo "Downloading complete Raspberry Pi firmware (includes bootloader, kernels, overlays)..."
wget -q --show-progress -O firmware.zip \
    "https://github.com/raspberrypi/firmware/archive/refs/heads/master.zip"

unzip -q firmware.zip

# Install bootloader files (start*.elf, fixup*.dat)
echo "Installing bootloader files..."
install -m 644 firmware-master/boot/*.elf "${ROOTFS_DIR}/boot/"
install -m 644 firmware-master/boot/*.dat "${ROOTFS_DIR}/boot/"
install -m 644 firmware-master/boot/bootcode.bin "${ROOTFS_DIR}/boot/"

# Install kernels
echo "Installing Pi 5 kernel (6.12+)..."
install -m 644 firmware-master/boot/kernel_2712.img "${ROOTFS_DIR}/boot/"
install -m 644 firmware-master/boot/kernel8.img "${ROOTFS_DIR}/boot/"

# Install all device trees (Pi 0-5)
echo "Installing device trees..."
install -m 644 firmware-master/boot/*.dtb "${ROOTFS_DIR}/boot/"

# Install overlays
echo "Installing device tree overlays..."
mkdir -p "${ROOTFS_DIR}/boot/overlays"
install -m 644 firmware-master/boot/overlays/*.dtbo "${ROOTFS_DIR}/boot/overlays/"
if [ -f firmware-master/boot/overlays/README ]; then
    install -m 644 firmware-master/boot/overlays/README "${ROOTFS_DIR}/boot/overlays/"
fi

# Download and extract matching kernel modules from GitHub firmware repo
echo "Downloading kernel modules from firmware repo..."

# Try to download pre-built kernel modules package from Raspberry Pi repository
LATEST_KERNEL_URL=$(curl -s "https://archive.raspberrypi.com/debian/pool/main/r/raspberrypi-firmware/" | \
    grep -oE 'raspberrypi-kernel_[0-9]+%3a[0-9.]+-[0-9]+_arm64.deb' | \
    sort -V | tail -1 | sed 's/%3a/:/')

if [ -n "${LATEST_KERNEL_URL}" ]; then
    echo "Downloading latest kernel package: ${LATEST_KERNEL_URL}"
    wget -q --show-progress -O kernel.deb \
        "https://archive.raspberrypi.com/debian/pool/main/r/raspberrypi-firmware/${LATEST_KERNEL_URL}"
    
    # Extract and install kernel modules
    dpkg-deb -x kernel.deb "${KERNEL_TEMP}/extracted"
    
    # Copy kernel modules to rootfs
    if [ -d "${KERNEL_TEMP}/extracted/lib/modules" ]; then
        # Backup old modules if they exist
        if [ -d "${ROOTFS_DIR}/lib/modules" ] && [ "$(ls -A ${ROOTFS_DIR}/lib/modules 2>/dev/null)" ]; then
            echo "Backing up old kernel modules..."
            mv "${ROOTFS_DIR}/lib/modules" "${ROOTFS_DIR}/lib/modules.old"
        fi
        
        mkdir -p "${ROOTFS_DIR}/lib/modules"
        cp -r "${KERNEL_TEMP}/extracted/lib/modules/"* "${ROOTFS_DIR}/lib/modules/"
        echo "Installed kernel modules to rootfs"
        ls "${ROOTFS_DIR}/lib/modules/"
    fi
    
    # Download kernel headers package
    LATEST_HEADERS_URL=$(curl -s "https://archive.raspberrypi.com/debian/pool/main/r/raspberrypi-firmware/" | \
        grep -oE 'raspberrypi-kernel-headers_[0-9]+%3a[0-9.]+-[0-9]+_arm64.deb' | \
        sort -V | tail -1 | sed 's/%3a/:/')
    
    if [ -n "${LATEST_HEADERS_URL}" ]; then
        echo "Downloading kernel headers: ${LATEST_HEADERS_URL}"
        wget -q --show-progress -O headers.deb \
            "https://archive.raspberrypi.com/debian/pool/main/r/raspberrypi-firmware/${LATEST_HEADERS_URL}"
        dpkg-deb -x headers.deb "${KERNEL_TEMP}/headers"
        
        # Install headers to rootfs
        if [ -d "${KERNEL_TEMP}/headers/usr" ]; then
            cp -r "${KERNEL_TEMP}/headers/usr/"* "${ROOTFS_DIR}/usr/"
            echo "Installed kernel headers"
        fi
    fi
else
    echo "WARNING: Could not find kernel modules package, using firmware package modules"
    # Fallback: Use modules from firmware package if available
    if [ -d firmware-master/modules ]; then
        cp -r firmware-master/modules/* "${ROOTFS_DIR}/lib/modules/" 2>/dev/null || true
    fi
fi

# Cleanup
rm -rf "${KERNEL_TEMP}"

echo "Pi 5 kernel installation complete!"
echo "Kernel files installed:"
ls -lh "${ROOTFS_DIR}/boot/kernel"*.img
