#!/bin/bash
set -x
set -e

DEBIAN_RELEASE=bookworm
DEBIAN_WORKDIR="$HOME"/debian-image-from-scratch
RAW_DEBIAN_IMAGE_PATH=${DEBIAN_WORKDIR}/debian-${DEBIAN_RELEASE}-image.raw

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

# Start the loop device
sudo losetup -fP ${RAW_DEBIAN_IMAGE_PATH}

# Check the status of the loop device
sudo losetup -a

# Mount root and /boot/efi directory
sudo mount /dev/loop0p2 "${DEBIAN_WORKDIR}"/chroot
sudo mount /dev/loop0p1 "${DEBIAN_WORKDIR}"/chroot/boot/efi

# Prepare mount points before chroot
prepare_mountpoints_before_chroot

# Chroot and execute the script
sudo chroot "${DEBIAN_WORKDIR}"/chroot
