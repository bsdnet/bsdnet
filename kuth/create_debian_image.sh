#!/bin/bash

set -x
set -e

DEBIAN_RELEASE=bookworm
DEBIAN_WORKDIR=debian-image-from-scratch
DEBIAN_IMAGE_NAME=debian-${DEBIAN_RELEASE}-image
DEBIAN_CACHE=debian-cache
CHROOT_DEBIAN_CMDS=chroot_debian_cmds.sh
CHROOT_VBOX_GUEST_ADDITIONS=chroot_install_vbox_guest_additions.sh

function cleanup_exit {
  # Unbind mount points
  sudo umount "$HOME"/${DEBIAN_WORKDIR}/chroot/dev
  sudo umount "$HOME"/${DEBIAN_WORKDIR}/chroot/run

  # Umount loop partitions
  sudo umount "$HOME"/${DEBIAN_WORKDIR}/chroot/boot
  sudo umount "$HOME"/${DEBIAN_WORKDIR}/chroot
}

# Call the cleanup_exit whenever exit
trap cleanup_exit EXIT

# Create a folder to store the image
rm -fR "${HOME:?}"/${DEBIAN_WORKDIR}
mkdir "$HOME"/${DEBIAN_WORKDIR}

if [[ ! -d "$HOME"/${DEBIAN_CACHE} ]]; then
	mkdir "$HOME"/${DEBIAN_CACHE}
fi

# Create an empty virtual harddriver file (30Gb)
dd \
  if=/dev/zero \
  of=~/${DEBIAN_WORKDIR}/${DEBIAN_IMAGE_NAME}.raw \
  bs=1 \
  count=0 \
  seek=32212254720 \
  status=progress
  
# Create partitions on the file
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | sudo fdisk ~/${DEBIAN_WORKDIR}/${DEBIAN_IMAGE_NAME}.raw 
o # clear the in memory partition table
n # new partition
p # primary partition
1 # partition number 1 
    # default - start at beginning of disk
+512M # 512 MB boot parttion
n # new partition
p # primary partition
2 # partion number 2
    # default, start immediately after preceding partition
    # default, extend partition to end of disk
a # make a partition bootable
1 # bootable partition is partition 1 -- /dev/loop0p1
p # print the in-memory partition table
w # write the partition table
q # and we're done
EOF

# Start the loop device
sudo losetup -fP ~/${DEBIAN_WORKDIR}/${DEBIAN_IMAGE_NAME}.raw

# Check the status of the loop device
sudo losetup -a

# Check the partions on the loop device
sudo fdisk -l /dev/loop0

# Format the loop0p1 device(/bot)
sudo mkfs.ext4 /dev/loop0p1

# Format the loop0p2 device(/)
sudo mkfs.ext4 /dev/loop0p2

# Create the chroot directory
mkdir ~/${DEBIAN_WORKDIR}/chroot
sudo mkdir ~/${DEBIAN_WORKDIR}/chroot/boot

# Mount the root partition
sudo mount /dev/loop0p2 ~/${DEBIAN_WORKDIR}/chroot

# Create and mount the boot partition
sudo mount /dev/loop0p1 ~/${DEBIAN_WORKDIR}/chroot/boot

# Bootstrap debian by running debootstrap
sudo debootstrap \
   --arch=amd64 \
   --variant=minbase \
   --cache-dir="$HOME"/${DEBIAN_CACHE} \
   --components "main" \
   --include "ca-certificates,cron,iptables,isc-dhcp-client,libnss-myhostname,ntp,ntpdate,rsyslog,ssh,sudo,dialog,whiptail,man-db,curl,dosfstools,e2fsck-static" \
   ${DEBIAN_RELEASE} \
   "$HOME"/${DEBIAN_WORKDIR}/chroot \
   http://deb.debian.org/debian/
   
# Configure external mount points
sudo mount --bind /dev "$HOME"/${DEBIAN_WORKDIR}/chroot/dev
sudo mount --bind /run "$HOME"/${DEBIAN_WORKDIR}/chroot/run

# Copy script into chroot
sudo cp ${CHROOT_DEBIAN_CMDS} ~/${DEBIAN_WORKDIR}/chroot/
sudo cp ${CHROOT_VBOX_GUEST_ADDITIONS} ~/${DEBIAN_WORKDIR}/chroot/

# Chroot and execute the script.
sudo chroot "$HOME"/${DEBIAN_WORKDIR}/chroot ./${CHROOT_DEBIAN_CMDS}

# Unbind mount points
sudo umount "$HOME"/${DEBIAN_WORKDIR}/chroot/dev
sudo umount "$HOME"/${DEBIAN_WORKDIR}/chroot/run

# Umount loop partitions
sudo umount "$HOME"/${DEBIAN_WORKDIR}/chroot/boot
sudo umount "$HOME"/${DEBIAN_WORKDIR}/chroot

# Check disks integrity
sudo fsck -f -y -v /dev/loop0p1
sudo fsck -f -y -v /dev/loop0p2

# Detach all associated loop devices
sudo losetup -D

# Create the VirtualBox base image
# create_vbox_base_image.sh

# Clean up
# rm -rf "$HOME"/${DEBIAN_WORKDIR}
