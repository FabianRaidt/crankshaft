#!/bin/bash -e

on_chroot << 'EOF'
set -e
set -x
export PIP_BREAK_SYSTEM_PACKAGES=1
if ! command -v python3 >/dev/null; then
	apt-get update
	apt-get install -y --no-install-recommends python3
fi
if ! command -v pip3 >/dev/null; then
	python3 -m ensurepip --default-pip || true
fi
if ! command -v pip3 >/dev/null; then
	apt-get update
	apt-get install -y --no-install-recommends python3-pip python3-setuptools python3-wheel
fi
python3 -m pip install --upgrade --break-system-packages pip
python3 -m pip install --break-system-packages python-tsl2591
EOF
