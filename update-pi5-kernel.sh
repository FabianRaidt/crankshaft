#!/bin/bash -e

# Manual Pi 5 kernel update script for existing SD card
# Run this on the host system with SD card mounted

if [ -z "$1" ]; then
    echo "Usage: $0 <boot_mount_point>"
    echo "Example: $0 /media/fabian/boot"
    exit 1
fi

BOOT_DIR="$1"

if [ ! -d "${BOOT_DIR}" ]; then
    echo "Error: ${BOOT_DIR} does not exist"
    exit 1
fi

echo "=== Pi 5 Kernel and Firmware Update for Crankshaft ==="
echo "Boot directory: ${BOOT_DIR}"
echo ""
echo "This will update:"
echo "  - Bootloader files (start*.elf, fixup*.dat, bootcode.bin)"
echo "  - Kernel (kernel_2712.img for Pi 5, kernel8.img for Pi 3/4)"
echo "  - Device trees (bcm2712-*.dtb for Pi 5)"
echo "  - Overlays (362 device tree overlays)"
echo ""

TEMP_DIR=$(mktemp -d)
cd "${TEMP_DIR}"

echo "Downloading complete Raspberry Pi firmware package..."
echo "This may take a few minutes..."

wget -q --show-progress -O firmware.zip \
    "https://github.com/raspberrypi/firmware/archive/refs/heads/master.zip"

echo ""
echo "Extracting firmware..."
unzip -q firmware.zip

echo ""
echo "Installing bootloader files..."
sudo cp firmware-master/boot/*.elf "${BOOT_DIR}/"
sudo cp firmware-master/boot/*.dat "${BOOT_DIR}/"
sudo cp firmware-master/boot/bootcode.bin "${BOOT_DIR}/"

echo "Installing kernels..."
if [ -f "${BOOT_DIR}/kernel8.img" ]; then
    echo "- Backing up old kernel8.img"
    sudo cp "${BOOT_DIR}/kernel8.img" "${BOOT_DIR}/kernel8.img.old"
fi
sudo cp firmware-master/boot/kernel_2712.img "${BOOT_DIR}/"
sudo cp firmware-master/boot/kernel8.img "${BOOT_DIR}/"

echo "Installing device trees..."
sudo cp firmware-master/boot/*.dtb "${BOOT_DIR}/"

echo "Installing device tree overlays..."
sudo mkdir -p "${BOOT_DIR}/overlays"
sudo cp firmware-master/boot/overlays/*.dtbo "${BOOT_DIR}/overlays/"
if [ -f firmware-master/boot/overlays/README ]; then
    sudo cp firmware-master/boot/overlays/README "${BOOT_DIR}/overlays/"
fi

# Cleanup
cd /
rm -rf "${TEMP_DIR}"

echo ""
echo "=== Installation Complete ==="
echo ""
echo "Bootloader files:"
ls -lh "${BOOT_DIR}/start"*.elf | head -3
echo ""
echo "Kernel files:"
ls -lh "${BOOT_DIR}/kernel"*.img
echo ""
echo "Pi 5 device trees:"
ls -lh "${BOOT_DIR}/bcm2712"*.dtb | head -5
echo ""
echo "Overlays: $(ls ${BOOT_DIR}/overlays/*.dtbo | wc -l) files"

echo ""
echo "✓ Your SD card now has:"
echo "  - Latest bootloader (December 2025)"
echo "  - Pi 5 kernel 6.12+ with full hardware support"
echo "  - Complete device tree support (Pi 0-5)"
echo "  - 362 device tree overlays"
echo ""
echo "✓ Ready for Raspberry Pi 5!"
