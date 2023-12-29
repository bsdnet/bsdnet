#!/bin/bash

set -x
set -e

DEBIAN_RELEASE=bookworm

# Configure the mount points, home and locale
mount none -t proc /proc
mount none -t sysfs /sys
mount none -t devpts /dev/pts

export HOME=/root
export LC_ALL=C

# Set a custom hostname
echo "debian-image" > /etc/hostname

# Configure apt sources.list
cat <<EOF > /etc/apt/sources.list
deb http://deb.debian.org/debian/ ${DEBIAN_RELEASE} main contrib non-free
deb-src http://deb.debian.org/debian/ ${DEBIAN_RELEASE} main contrib non-free

deb http://deb.debian.org/debian/ ${DEBIAN_RELEASE}-updates main contrib non-free
deb-src http://deb.debian.org/debian/ ${DEBIAN_RELEASE}-updates main contrib non-free

deb http://deb.debian.org/debian-security ${DEBIAN_RELEASE}-security main
deb-src http://deb.debian.org/debian-security ${DEBIAN_RELEASE}-security main
EOF

# Configure fstab
cat <<EOF > /etc/fstab
# /etc/fstab: static file system information.
#
# Use 'blkid' to print the universally unique identifier for a
# device; this may be used with UUID= as a more robust way to name devices
# that works even if disks are added and removed. See fstab(5).
#
# <file system>         <mount point>   <type>  <options>                       <dump>  <pass>
/dev/sda2               /               ext4    errors=remount-ro               0       1
/dev/sda1               /boot           ext4    defaults                        0       2
EOF

# Update the apt packages indexes
apt-get update

# Install systemd
apt-get install -y systemd-sysv


# Configure machine-id
dbus-uuidgen > /etc/machine-id

# Force dpkg not install a file into its location.
dpkg-divert --local --rename --add /sbin/initctl
ln -s /bin/true /sbin/initctl

# Install the base packages
apt-get install -y \
    os-prober \
    ifupdown \
    network-manager \
    resolvconf \
    locales \
    build-essential \
    module-assistant \
    cloud-init \
    grub-pc \
    grub2 \
    linux-image-amd64 \
    linux-headers-amd64

# Configure the network interfaces
cat <<EOF > /etc/network/interfaces
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

source /etc/network/interfaces.d/*

# The loopback network interface
auto lo
iface lo inet loopback
EOF

# Reconfigure the locales
dpkg-reconfigure locales

# Reconfigure resolveconf
dpkg-reconfigure resolvconf

# Configure network-manager
cat <<EOF > /etc/NetworkManager/NetworkManager.conf
[main]
rc-manager=resolvconf
plugins=ifupdown,keyfile
dns=default

[ifupdown]
managed=false
EOF

# Disable networkd
systemctl mask systemd-networkd.socket systemd-networkd networkd-dispatcher systemd-networkd-wait-online

# Disable resovled
systemctl mask systemd-resolved

# Reconfigure network-manager
dpkg-reconfigure network-manager

# Configure the grub
cat <<EOF > /etc/default/grub
GRUB_DEFAULT=0
GRUB_TIMEOUT=0
GRUB_DISTRIBUTOR=$(lsb_release -i -s 2> /dev/null || echo Debian)
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash nomodeset"
GRUB_CMDLINE_LINUX=""
EOF

# Install grub
grub-install /dev/loop0

# Update grub configuration
update-grub

#Install VirtualBox Guest Additions
install_vbox_guest_additions.sh

# Reset machine id
truncate -s 0 /etc/machine-id

# Remove the diversion
rm /sbin/initctl

dpkg-divert --rename --remove /sbin/initctl

# Clean up

apt-get autoclean

rm -rf /tmp/* ~/.bash_history

umount /proc

umount /sys

umount /dev/pts

export HISTSIZE=0

exit
