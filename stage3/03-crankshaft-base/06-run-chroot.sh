#!/bin/bash -e

ARCH=$(dpkg --print-architecture)

if [ "${ARCH}" = "armhf" ]; then
	apt-get purge wiringpi -y || true
	hash -r
	dpkg -i /root/wiringpi-latest.deb
else
	echo "Skipping wiringpi install on ${ARCH}"
fi
