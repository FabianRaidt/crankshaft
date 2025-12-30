#!/bin/bash -e

if [ ! -d "${ROOTFS_DIR}" ]; then
	copy_previous
fi

# Detect architecture without relying on dpkg in chroot (can fail if qemu/binfmt missing)
# Always prefer configured target arch and fall back to arm64 rather than incorrectly
# choosing armv7 when detection is inconclusive.
ARCH="${APT_ARCH:-}"

if [ -z "$ARCH" ]; then
	ARCH=$(on_chroot uname -m 2>/dev/null || true)
fi

if [ -z "$ARCH" ] || [ "$ARCH" = "armv7l" ]; then
	echo "Architecture detection inconclusive ($ARCH), defaulting to arm64 target"
	ARCH="arm64"
fi

if [ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "aarch64_be" ]; then
	export ARCH_SUFFIX="arm64"
	echo "Detected ARM64 architecture - using arm64 prebuilts"
else
	export ARCH_SUFFIX="armv7"
	echo "Detected ARMhf architecture - using armv7 prebuilts"
fi
