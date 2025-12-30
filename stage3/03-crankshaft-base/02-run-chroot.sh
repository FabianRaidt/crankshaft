#!/bin/bash -e

# Add debug output to track script execution
exec 19>>/tmp/chroot-script-debug.log
BASH_XTRACEFD="19"
set -x

if [ -f $CONTINUE ]; then
  set +e
fi

# Wrapper for potentially hanging commands
safe_systemctl() {
  timeout 10 systemctl "$@" || {
    ret=$?
    if [ $ret -eq 124 ]; then
      echo "WARNING: systemctl $@ timed out, continuing anyway"
      return 0
    fi
    echo "WARNING: systemctl $@ failed with exit $ret, continuing"
    return 0
  }
}

# Lightweight unit presence check
unit_exists() {
  systemctl list-unit-files | awk '{print $1}' | grep -Fxq "$1"
}

enable_unit() {
  if unit_exists "$1"; then
    safe_systemctl enable "$1"
  else
    echo "Skipping $1 enable (unit not installed)"
  fi
}

disable_unit() {
  if unit_exists "$1"; then
    safe_systemctl disable "$1"
  else
    echo "Skipping $1 disable (unit not installed)"
  fi
}

# Set lang
SETLANG=en_GB

sed -i -e '/^#/! s/./# &/' /etc/locale.gen # disable all entries by adding # in line start
sed -i "s/^# $SETLANG.UTF-8 UTF-8/$SETLANG.UTF-8 UTF-8/" /etc/locale.gen # enable lang
dpkg-reconfigure --frontend=noninteractive locales
update-locale LANG=$SETLANG.UTF-8

# we don't need to resize the root part
sed -i 's/ init\=.*$//' /boot/cmdline.txt

# config.txt
echo "" >> /boot/config.txt
echo "# Custom power settings" >> /boot/config.txt
echo "max_usb_current=1" >> /boot/config.txt

echo "" >> /boot/config.txt
echo "# Disable the PWR LED." >> /boot/config.txt
echo "dtparam=pwr_led_trigger=none" >> /boot/config.txt
echo "dtparam=pwr_led_activelow=off" >> /boot/config.txt

echo "" >> /boot/config.txt
echo "# Disable Rainbow splash" >> /boot/config.txt
echo "disable_splash=1" >> /boot/config.txt

echo "" >> /boot/config.txt
echo "# Overscan fix" >> /boot/config.txt
echo "overscan_scale=1" >> /boot/config.txt

echo "" >> /boot/config.txt
echo "# Enable watchdog" >> /boot/config.txt
echo "dtparam=watchdog=on" >> /boot/config.txt

echo "" >> /boot/config.txt
echo "# Boot time improvements" >> /boot/config.txt
echo "boot_delay=0" >> /boot/config.txt
echo "initial_turbo=30" >> /boot/config.txt
echo "start_cd=1" >> /boot/config.txt
echo "#dtoverlay=sdtweak,overclock_50=100" >> /boot/config.txt

# enable vc4 for rpi3 as well
#sed -i 's/#dtoverlay=vc4-fkms-v3d/dtoverlay=vc4-fkms-v3d/' /boot/config.txt

# pulseaudio
cat /etc/pulse/csng_daemon.conf >> /etc/pulse/daemon.conf
cat /etc/pulse/csng_default.pa > /etc/pulse/default.pa
cat /etc/pulse/csng_system.pa > /etc/pulse/system.pa
rm /etc/pulse/csng_daemon.conf
rm /etc/pulse/csng_default.pa
rm /etc/pulse/csng_system.pa

# wallaper's
ln -sf /boot/crankshaft/wallpaper.png /home/pi/wallpaper.png
ln -sf /boot/crankshaft/wallpaper-night.png /home/pi/wallpaper-night.png
ln -sf /boot/crankshaft/wallpaper-classic.png /home/pi/wallpaper-classic.png
ln -sf /boot/crankshaft/wallpaper-classic-night.png /home/pi/wallpaper-classic-night.png
ln -sf /boot/crankshaft/wallpaper-eq.png /home/pi/wallpaper-eq.png

# custom plymouth
ln -sf /boot/crankshaft/splash.png /usr/share/plymouth/themes/custom/splash.png
ln -sf /boot/crankshaft/shutdown.png /usr/share/plymouth/themes/custom/shutdown.png

# custom usbcamera-overlay
ln -sf /boot/crankshaft/usbcamera-overlay.png /opt/crankshaft/cam_overlay/overlay.png

# triggerhappy
sed -i 's/user nobody/user pi/' /lib/systemd/system/triggerhappy.service
ln -sf /boot/crankshaft/triggerhappy.conf /etc/triggerhappy/triggers.d/crankshaft.conf

# set the hostname
echo "CRANKSHAFT-NG" > /etc/hostname
sed -i "s/raspberrypi/CRANKSHAFT-NG/" /etc/hosts

# Boost system performance
sed -i 's/reboot.target/shutdown.target/g' /lib/systemd/system/rpi-display-backlight.service

# set gpsd settings
sed -i 's/GPSD_OPTIONS=\"\"/GPSD_OPTIONS=\"-n\"/g' /etc/default/gpsd
echo "" >> /etc/ntp.conf
echo "server 127.127.28.0 minpoll 4 maxpoll 4 prefer" >> /etc/ntp.conf
echo "fudge 127.127.28.0 time1 -1.25 refid GPS" >> /etc/ntp.conf

# Set default startup services state (ignore missing units to stay idempotent)
enable_unit gpio2kbd.service
enable_unit crankshaft.service
enable_unit btservice.service
enable_unit user_startup.service
enable_unit devmode.service
enable_unit debugmode.service
enable_unit display.service
enable_unit user_startup.service
enable_unit update.timer
enable_unit usbrestore.service
enable_unit usbdetect.service
enable_unit usbunmount.service
enable_unit daymode.timer
enable_unit nightmode.timer
enable_unit tap2wake.service
enable_unit openauto.service
enable_unit gpiotrigger.service
enable_unit timerstart.service
enable_unit regensshkeys.service
enable_unit ssh.service
enable_unit pulseaudio.service
enable_unit pacheck.service
disable_unit rpi-display-backlight.service
enable_unit rpi-display-backlight.service
enable_unit hotspot.service
enable_unit alsastaterestore.service
enable_unit systemd-timesyncd.service
enable_unit networking.service
enable_unit dhcpcd.service
enable_unit lightsensor.service
enable_unit i2ccheck.service
enable_unit wpa-monitor.service
enable_unit custombrightness.service
enable_unit gpsd.service
enable_unit watchdog.service
disable_unit hotspot-monitor.service
disable_unit wpa_supplicant.service
disable_unit hwclock-load.service
disable_unit rpicamserver.service
#systemctl disable regenerate_ssh_host_keys.service
#systemctl disable wifisetup.service
disable_unit systemd-rfkill.service
disable_unit systemd-rfkill.socket
disable_unit resize2fs_once.service
disable_unit bluetooth.service
disable_unit hciuart.service
disable_unit hostapd.service
disable_unit dnsmasq.service
disable_unit alsa-state.service
disable_unit apply_noobs_os_config.service
disable_unit wifi-country.service
disable_unit alsa-restore.service
disable_unit alsa-state.service
disable_unit raspi-config.service
disable_unit systemd-fsck@.service
disable_unit smbd.service
disable_unit nmbd.service
disable_unit gldriver-test.service
disable_unit dphys-swapfile.service
disable_unit systemd-timesyncd.service
disable_unit systemd-fsck@dev-mmcblk0p1.service

rm -f /lib/systemd/system/systemd-rfkill.service
rm -f /lib/systemd/system/systemd-rfkill.socket
rm -f /lib/systemd/system/apt-daily.timer
rm -f /lib/systemd/system/apt-daily.service
rm -f /lib/systemd/system/apt-daily-upgrade.timer
rm -f /lib/systemd/system/apt-daily-upgrade.service
rm -f /etc/systemd/system/timers.target.wants/apt-daily.timer
rm -f /etc/systemd/system/timers.target.wants/apt-daily-upgrade.timer
rm -f /lib/systemd/system/timers.target.wants/systemd-tmpfiles-clean.timer
rm -f /lib/systemd/system/apply_noobs_os_config.service


#systemctl daemon-relaod

# set custom boot splash
# csnganimation plugin is 32-bit only, use crankshaft theme for ARM64
if [ "$(dpkg --print-architecture)" = "arm64" ]; then
    plymouth-set-default-theme crankshaft
else
    plymouth-set-default-theme csnganimation
fi

# create lib cache
timeout 60 ldconfig || true

# add gettys
safe_systemctl enable getty@tty3.service
# Don't kill still running getty - fixes restart in x11 mode during boot
sed -i 's/^TTYVHangup=.*/TTYVHangup=no/' /lib/systemd/system/getty@.service

# enable splash and set default console
sed -i 's/console=tty1/console=tty3/' /boot/cmdline.txt
sed -i 's/console=serial0,115200 //' /boot/cmdline.txt

# add special settings
sed -i 's/$/ logo.nologo loglevel=0 vt.global_cursor_default=0 noswap splash plymouth.ignore-serial-consoles consoleblank=0 ipv6.disable=1/' /boot/cmdline.txt

# Banner for ssh
sed -i 's/#Banner none/Banner \/etc\/issue.net/' /etc/ssh/sshd_config

# Lisen on all interfaces ssh
sed -i 's/^#ListenAddress 0.0.0.0/ListenAddress 0.0.0.0/' /etc/ssh/sshd_config

# OS Name
STRING="Welcome to Crankshaft CarOS (${IMG_DATE} / Build ${GIT_HASH})"
#sed -i "s/PRETTY_NAME=.*/PRETTY_NAME=${STRING}/g" /usr/lib/os-release
cp /usr/lib/os-release /usr/lib/os-release.bak
sed -i '/PRETTY_NAME=/d' /usr/lib/os-release.bak
echo "PRETTY_NAME=$STRING" > /usr/lib/os-release
cat /usr/lib/os-release.bak >> /usr/lib/os-release
rm /usr/lib/os-release.bak
echo "$STRING" > /etc/issue
echo "" >> /etc/issue
echo "$STRING" > /etc/issue.net
echo "" >> /etc/issue.net

# wifi
rm /etc/wpa_supplicant/wpa_supplicant.conf
ln -sf /tmp/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant.conf

# Enable systemd timesync; create a minimal config if it is missing to avoid sed errors
if [ ! -f /etc/systemd/timesyncd.conf ]; then
  mkdir -p /etc/systemd
  printf "[Time]\n" > /etc/systemd/timesyncd.conf
fi
sed -i 's/#NTP=.*/NTP=0.debian.pool.ntp.org 1.debian.pool.ntp.org 2.debian.pool.ntp.org 3.debian.pool.ntp.org/g' /etc/systemd/timesyncd.conf
sed -i 's/#FallbackNTP=.*/FallbackNTP=0.debian.pool.ntp.org 1.debian.pool.ntp.org 2.debian.pool.ntp.org 3.debian.pool.ntp.org/g' /etc/systemd/timesyncd.conf

# add alias for mc to stay inside folder after exit mc
echo "" >> /etc/bash.bashrc
echo "alias mc='. /usr/share/mc/bin/mc-wrapper.sh'" >> /etc/bash.bashrc

# enable auto detection display
#sed -i 's/DISPLAY_AUTO_DETECT=0/DISPLAY_AUTO_DETECT=1/' /boot/crankshaft/crankshaft_env.sh

# Setup watchdog
sed -i 's/.*max-load-1	.*/max-load-1		= 2/' /etc/watchdog.conf
sed -i 's/.*watchdog-device.*/watchdog-device		= \/dev\/watchdog/' /etc/watchdog.conf
sed -i 's/.*temperatur-sensor.*/temperatur-sensor		= \/sys\/class\/thermal\/thermal_zone0\/temp/' /etc/watchdog.conf
sed -i 's/.*max-temperature.*/max-temperature		= 75/' /etc/watchdog.conf
sed -i 's/#retry-timeout.*/retry-timeout		= 30/' /etc/watchdog.conf
echo "watchdog-timeout	= 10" >> /etc/watchdog.conf


# Setup kernel panic behaviour
sed -i 's/.*kernel-panic.*//g' /etc/sysctl.conf
echo "kernel-panic = 10" >> /etc/sysctl.conf

# optimize wifi
echo "net.ipv4.tcp_window_scaling = 1" >> /etc/sysctl.conf
echo "net.core.rmem_max = 16777216" >> /etc/sysctl.conf
echo "net.ipv4.tcp_rmem = 4096 87380 16777216" >> /etc/sysctl.conf
echo "net.ipv4.tcp_wmem = 4096 16384 16777216" >> /etc/sysctl.conf

# Later start cpufrequtils
sed -i 's/# Required-Start: $remote_fs loadcpufreq.*/# Required-Start: $remote_fs loadcpufreq rc.local/' /etc/init.d/cpufrequtils

# Don't kill processes after exit session
sed -i 's/#KillUserProcesses=.*/KillUserProcesses=no/' /etc/systemd/logind.conf

# Boost system performance
sed -i 's/^GOVERNOR=.*/GOVERNOR="performance"/' /etc/init.d/cpufrequtils

# Grant access to system wide pulseaudio
usermod -G pulse,pulse-access -a root
usermod -G pulse,pulse-access -a pi
usermod -G pulse,pulse-access -a pulse

# Grant disk access for pi user
usermod -G disk -a pi

# Grant pulse access to input for keyboard control
usermod -G input -a pulse

# Set client conf for system wide usage
sed -i 's/.*Make sure client is correct configured for system wide usage.*//g' /etc/pulse/client.conf
sed -i 's/.*default-server =.*//g' /etc/pulse/client.conf
sed -i 's/.*autospawn =.*//g' /etc/pulse/client.conf
sed -i '$!N; /^\(.*\)\n\1$/!P; D' /etc/pulse/client.conf
echo "# Make sure client is correct configured for system wide usage" >> /etc/pulse/client.conf
echo "default-server = unix:/var/run/pulse/native" >> /etc/pulse/client.conf
echo "autospawn = no" >> /etc/pulse/client.conf

# Make udev mountpoints shared
sed -i 's/^MountFlags=.*/MountFlags=shared/' /lib/systemd/system/systemd-udevd.service

# link csmt
ln -sf /usr/local/bin/crankshaft /usr/local/bin/csmt

# Set path for rsyslogd
sed -i 's/\$WorkDirectory \/var\/spool\/rsyslog/\$WorkDirectory \/var\/spool/' /etc/rsyslog.conf

# exfat support was provided via exfat-nofuse DKMS, but the package is unavailable on bookworm
# and breaks the build. Skip this step to keep the pipeline moving.
echo "Skipping exfat DKMS build (exfat-nofuse not available)"

exit 0
