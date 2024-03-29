#!/bin/bash
set -x
#set -e

VIRTUALBOX_VERSION=7.0.12

function cleanup_exit {
  # Umount and remove the ISO file
  umount /mnt
  rm -rf VBoxGuestAdditions_${VIRTUALBOX_VERSION}.iso
}

trap cleanup_exit EXIT

# Download VirtualBox Guest Addtions
curl --progress-bar https://download.virtualbox.org/virtualbox/${VIRTUALBOX_VERSION}/VBoxGuestAdditions_${VIRTUALBOX_VERSION}.iso -o VBoxGuestAdditions_${VIRTUALBOX_VERSION}.iso

# Mount the ISO file
mount -o loop VBoxGuestAdditions_${VIRTUALBOX_VERSION}.iso /mnt

# Install Guest Additions
/mnt/VBoxLinuxAdditions.run --nox11

# Generate kernel modules
KERNEL_VERSION=$(ls /lib/modules)
rcvboxadd quicksetup "${KERNEL_VERSION}"

cleanup_exit

# Fix vboxadd-service
sed -i -e 's/ systemd-timesyncd.service//g' /lib/systemd/system/vboxadd-service.service

# Upgrade
apt-get -y upgrade
