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
# Disk layout
# 1 EFI-SYSTEM  Bootloader FAT32      256M
# 2 ROOT-A      Root filesystem  EXT2 5G
# 3 ROOT-B      Root filesystem  EXT2 5G
# 4 CFG         Configuration    EXT4 128M
# 5 DATA1        Data partition  EXT4 5G // For container image or customer installed application
# 6 DATA2        Data partition  EXT4 5G // For obeservility metrics
# 7 LOG         Log partition    EXT4 10G
#
: <<comment
parted -s -a optimal -- ${RAW_DEBIAN_IMAGE_PATH} \
	mklabel gpt \
	mkpart primary fat32 1MiB 256MiB \
	mkpart primary ext2  256MiB 5376MiB \
        mkpart primary ext2  5376MiB 10490MiB \
        mkpart primary ext4  10490MiB 10624MiB  \
        mkpart primary ext4  10624MiB 15744MiB\
        mkpart primary ext4  15744GiB 20864MiB\
        mkpart primary ext4  20864MiB  \
        set 1 esp on
comment

sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | sudo fdisk ${RAW_DEBIAN_IMAGE_PATH}
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
sudo losetup -fP ${RAW_DEBIAN_IMAGE_PATH}

# Check the status of the loop device
sudo losetup -a

# Check the partions on the loop device
sudo fdisk -l /dev/loop0

# Format the loop0p1 device(/bot)
sudo mkfs.ext4 /dev/loop0p1

# Format the loop0p2 device(/)
sudo mkfs.ext4 /dev/loop0p2

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
   --include "ca-certificates,cron,iptables,isc-dhcp-client,libnss-myhostname,ntp,ntpdate,rsyslog,ssh,sudo,dialog,whiptail,man-db,curl,dosfstools,e2fsck-static" \
   ${DEBIAN_RELEASE} \
   ${DEBIAN_WORKDIR}/chroot \
   http://deb.debian.org/debian/
   
# Configure external mount points
sudo mount --bind /dev ${DEBIAN_WORKDIR}/chroot/dev
sudo mount --bind /run ${DEBIAN_WORKDIR}/chroot/run
sudo mount -t proc none ${DEBIAN_WORKDIR}/chroot/proc
sudo mount -t sysfs none ${DEBIAN_WORKDIR}/chroot/sys
sudo mount -t devpts none ${DEBIAN_WORKDIR}/chroot//dev/pts

# Copy script into chroot
sudo cp ${CHROOT_DEBIAN_CMDS} ${DEBIAN_WORKDIR}/chroot/
sudo cp ${CHROOT_VBOX_GUEST_ADDITIONS} ${DEBIAN_WORKDIR}/chroot/

# Chroot and execute the script.
sudo chroot ${DEBIAN_WORKDIR}/chroot ./${CHROOT_DEBIAN_CMDS}

cleanup_exit

# Check disks integrity
sudo fsck -f -y -v /dev/loop0p1
sudo fsck -f -y -v /dev/loop0p2

# Detach all associated loop devices
sudo losetup -D

# Create the VirtualBox base image
# create_vbox_base_image.sh

# Clean up
# rm -rf ${DEBIAN_WORKDIR}
