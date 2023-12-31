#!/bin/bash
set -x
set -e

DEBIAN_RELEASE=bookworm
DEBIAN_ARCH=amd64
DEBIAN_WORKDIR="$HOME"/debian-image-from-scratch
RAW_DEBIAN_IMAGE_PATH=${DEBIAN_WORKDIR}/debian-${DEBIAN_RELEASE}-image.raw
DEBIAN_CACHEDIR="$HOME"/debian-cache

# Scripts to be copied into target machine
CHROOT_DEBIAN_CMDS=chroot_debian_cmds.sh
CHROOT_VBOX_GUEST_ADDITIONS=chroot_install_vbox_guest_additions.sh

function prepare_mountpoints_before_chroot {
  # Configure external mount points
  sudo mount --bind /dev ${DEBIAN_WORKDIR}/chroot/dev
  sudo mount --bind /run ${DEBIAN_WORKDIR}/chroot/run
  sudo mount -t proc none ${DEBIAN_WORKDIR}/chroot/proc
  sudo mount -t sysfs none ${DEBIAN_WORKDIR}/chroot/sys
  sudo mount -t devpts none ${DEBIAN_WORKDIR}/chroot/dev/pts
}

function cleanup_after_chroot {
  # Unbind mount points
  sudo umount ${DEBIAN_WORKDIR}/chroot/proc
  sudo umount ${DEBIAN_WORKDIR}/chroot/sys
  sudo umount ${DEBIAN_WORKDIR}/chroot/dev/pts
  sudo umount ${DEBIAN_WORKDIR}/chroot/dev
  sudo umount ${DEBIAN_WORKDIR}/chroot/run
  
  # Umount loop partitions
  sudo umount ${DEBIAN_WORKDIR}/chroot/boot/efi
  sudo umount ${DEBIAN_WORKDIR}/chroot
}

# Call the cleanup_after_chroot whenever erroing out
trap cleanup_after_chroot ERR

# Create a folder to store the image
sudo rm -fR ${DEBIAN_WORKDIR}
mkdir ${DEBIAN_WORKDIR}

# Use local cache if possible
if [[ ! -d ${DEBIAN_CACHEDIR} ]]; then
  mkdir ${DEBIAN_CACHEDIR}
fi

# Create an empty virtual harddriver file (30Gb)
dd if=/dev/zero of=${RAW_DEBIAN_IMAGE_PATH} \
  bs=1 count=0 seek=32212254720 \
  status=progress
  
# Create partitions on the disk
parted ${RAW_DEBIAN_IMAGE_PATH} --script mklabel gpt
parted --align optimal ${RAW_DEBIAN_IMAGE_PATH} --script mkpart primary fat32 1MiB 256MiB
parted ${RAW_DEBIAN_IMAGE_PATH} --script name 1 uefi
parted ${RAW_DEBIAN_IMAGE_PATH} --script set 1 esp on

# Create Linux partition
parted --align optimal ${RAW_DEBIAN_IMAGE_PATH} --script mkpart primary ext4 256MiB 100%
parted ${RAW_DEBIAN_IMAGE_PATH} --script name 2 root

# Start the loop device
sudo losetup -fP ${RAW_DEBIAN_IMAGE_PATH}

# Check the status of the loop device
sudo losetup -a

# Check the partions on the loop device
sudo parted /dev/loop0 print

# Format the loop0p1 device(/boot/efi)
sudo mkfs.vfat -F 32 -n EFI /dev/loop0p1

# Format the loop0p2 device(/)
sudo mkfs.ext4 -L LINUX /dev/loop0p2

# Create and mount root and /boot/efi directory
mkdir "${DEBIAN_WORKDIR}"/chroot
sudo mount /dev/loop0p2 "${DEBIAN_WORKDIR}"/chroot

sudo mkdir -p "${DEBIAN_WORKDIR}"/chroot/boot/efi
sudo mount /dev/loop0p1 "${DEBIAN_WORKDIR}"/chroot/boot/efi

# Bootstrap debian by running debootstrap
sudo debootstrap \
   --arch=${DEBIAN_ARCH} \
   --variant=minbase \
   --cache-dir=${DEBIAN_CACHEDIR} \
   --include "ca-certificates,cron,iptables,isc-dhcp-client,libnss-myhostname,chrony,rsyslog,ssh,sudo,dialog,whiptail,man-db,curl,dosfstools,e2fsck-static" \
   ${DEBIAN_RELEASE} \
   ${DEBIAN_WORKDIR}/chroot \
   http://deb.debian.org/debian/
   
# Copy scripts into chroot
sudo cp ${CHROOT_DEBIAN_CMDS}          "${DEBIAN_WORKDIR}"/chroot/
sudo cp ${CHROOT_VBOX_GUEST_ADDITIONS} "${DEBIAN_WORKDIR}"/chroot/

# Prepare mount points before chroot
prepare_mountpoints_before_chroot

# Chroot and execute the script
sudo chroot "${DEBIAN_WORKDIR}"/chroot ./${CHROOT_DEBIAN_CMDS}

# Clean up
cleanup_after_chroot

# Check disks integrity
sudo fsck -f -y -v /dev/loop0p1
sudo fsck -f -y -v /dev/loop0p2

# Detach all associated loop devices
sudo losetup -D

# Create the VirtualBox base image
./create_vbox_base_image.sh

#rm -rf ${DEBIAN_WORKDIR}
