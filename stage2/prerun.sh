#!/bin/bash -e

if [ ! -d "${ROOTFS_DIR}" ]; then
	copy_previous
fi

# Disable apt recommends and suggests to avoid problematic packages like ssh-import-id
mkdir -p "${ROOTFS_DIR}/etc/apt/apt.conf.d"
cat > "${ROOTFS_DIR}/etc/apt/apt.conf.d/99norecommends" << 'EOF'
APT::Install-Recommends "0";
APT::Install-Suggests "0";
EOF
