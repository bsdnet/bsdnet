#!/bin/bash
set -x
set -e

DEBIAN_RELEASE=bookworm

export HOME=/root
export LC_ALL=C
export DEBIAN_FRONTEND=noninteractive

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
/dev/sda1               /boot/efi       vfat    defaults                        0       2
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
    grub-efi \
    grub-efi-amd64 \
    linux-image-amd64 \
    linux-headers-amd64

# Set a custom hostname
echo "debian-image-${DEBIAN_RELEASE}" > /etc/hostname

# Configure the network interfaces
cat <<EOF > /etc/network/interfaces
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

source /etc/network/interfaces.d/*

# The loopback network interface
auto lo
iface lo inet loopback
EOF

# Configure the timezone
DEBCONF_NONINTERACTIVE_SEEN=true dpkg-reconfigure tzdata

# Reconfigure the locales
locale-gen --purge en_US.UTF-8
DEBCONF_NONINTERACTIVE_SEEN=true dpkg-reconfigure locales

# Reconfigure resolveconf
DEBCONF_NONINTERACTIVE_SEEN=true dpkg-reconfigure resolvconf

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
DEBCONF_NONINTERACTIVE_SEEN=true dpkg-reconfigure network-manager

# Configure the grub
cat <<EOF > /etc/default/grub
GRUB_DEFAULT=0
GRUB_TIMEOUT=0
GRUB_DISTRIBUTOR=$(lsb_release -i -s 2> /dev/null || echo Debian)
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash nomodeset"
GRUB_CMDLINE_LINUX=""
EOF

# Install and update grub configuration
grub-install --target x86_64-efi
update-grub

# Make it bootable for Virtualbox
mkdir /boot/efi/EFI/BOOT
cp /boot/efi/EFI/debian/fbx64.efi /boot/efi/EFI/BOOT/bootx64.efi

# Install VirtualBox Guest Additions
./chroot_install_vbox_guest_additions.sh
./chroot_install_additional_packages.sh
#./chroot_install_kubernetes.sh

# Reset machine id
truncate -s 0 /etc/machine-id

# Remove the diversion
rm /sbin/initctl
dpkg-divert --rename --remove /sbin/initctl

# Clean up
apt-get autoclean
rm -rf /tmp/* $HOME/.bash_history
rm ./chroot_install_vbox_guest_additions.sh
rm ./chroot_debian_cmds.sh
export HISTSIZE=0
exit
