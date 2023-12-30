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

function prepare_mountpoints {
  # Configure external mount points
  sudo mount --bind /dev ${DEBIAN_WORKDIR}/chroot/dev
  sudo mount --bind /run ${DEBIAN_WORKDIR}/chroot/run
  sudo mount -t proc none ${DEBIAN_WORKDIR}/chroot/proc
  sudo mount -t sysfs none ${DEBIAN_WORKDIR}/chroot/sys
  sudo mount -t devpts none ${DEBIAN_WORKDIR}/chroot//dev/pts
}

function cleanup_exit {
  # Unbind mount points
  sudo umount ${DEBIAN_WORKDIR}/chroot/proc
  sudo umount ${DEBIAN_WORKDIR}/chroot/sys
  sudo umount ${DEBIAN_WORKDIR}/chroot/dev/pts
  sudo umount ${DEBIAN_WORKDIR}/chroot/dev
  sudo umount ${DEBIAN_WORKDIR}/chroot/run
  
  # Umount loop partitions
  sudo umount ${DEBIAN_WORKDIR}/chroot/boot
  sudo umount ${DEBIAN_WORKDIR}/chroot

  # Detach all associated loop devices
  sudo losetup -D
}

# Call the cleanup_exit whenever exit
trap cleanup_exit EXIT

# Create a folder to store the image
rm -fR ${DEBIAN_WORKDIR}
mkdir ${DEBIAN_WORKDIR}

# Use local cache if possible
if [[ ! -d ${DEBIAN_CACHEDIR} ]]; then
	mkdir ${DEBIAN_CACHEDIR}
fi

# Create an empty virtual harddriver file (30Gb)
dd \
  if=/dev/zero \
  of=${RAW_DEBIAN_IMAGE_PATH} \
  bs=1 \
  count=0 \
  seek=32212254720 \
  status=progress
  
# Create partitions on the disk
parted ${RAW_DEBIAN_IMAGE_PATH} --script mklabel gpt
parted ${RAW_DEBIAN_IMAGE_PATH} --script mkpart EFI fat32 1MiB 256MiB
parted ${RAW_DEBIAN_IMAGE_PATH} --script set 1 esp on

parted ${RAW_DEBIAN_IMAGE_PATH} --script mkpart LINUX ext4 1MiB 100% 

# Start the loop device
sudo losetup -fP ${RAW_DEBIAN_IMAGE_PATH}

# Check the status of the loop device
sudo losetup -a

# Check the partions on the loop device
sudo parted /dev/loop0 print

# Format the loop0p1 device(/efi)
sudo mkfs.vfat -n EFI /dev/loop0p1

# Format the loop0p2 device(/)
sudo mkfs.ext4 -L LINUX /dev/loop0p2

# Create and mount root directory
mkdir ${DEBIAN_WORKDIR}/chroot
sudo mount /dev/loop0p2 ${DEBIAN_WORKDIR}/chroot

# Create and mount the boot partition
sudo mkdir ${DEBIAN_WORKDIR}/chroot/boot
sudo mount /dev/loop0p1 ${DEBIAN_WORKDIR}/chroot/boot

# Bootstrap debian by running debootstrap
sudo debootstrap \
   --arch=${DEBIAN_ARCH} \
   --variant=minbase \
   --cache-dir=${DEBIAN_CACHEDIR} \
   --include "ca-certificates,cron,iptables,isc-dhcp-client,libnss-myhostname,chrony,rsyslog,ssh,sudo,dialog,whiptail,man-db,curl,dosfstools,e2fsck-static" \
   ${DEBIAN_RELEASE} \
   ${DEBIAN_WORKDIR}/chroot \
   http://deb.debian.org/debian/
   
# Copy script into chroot
sudo cp ${CHROOT_DEBIAN_CMDS} ${DEBIAN_WORKDIR}/chroot/
sudo cp ${CHROOT_VBOX_GUEST_ADDITIONS} ${DEBIAN_WORKDIR}/chroot/

# Prepare mount points for chroot
prepare_mountpoints

# Chroot and execute the script.
sudo chroot ${DEBIAN_WORKDIR}/chroot ./${CHROOT_DEBIAN_CMDS}

# Check disks integrity
sudo fsck -f -y -v /dev/loop0p1
sudo fsck -f -y -v /dev/loop0p2

# Create the VirtualBox base image
./create_vbox_base_image.sh

# Clean up
cleanup_exit

rm -rf ${DEBIAN_WORKDIR} 
