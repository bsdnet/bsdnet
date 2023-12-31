#!/bin/bash
set -x
set -e

DEBIAN_RELEASE=bookworm
DEBIAN_BASE_IMAGE=debian-${DEBIAN_RELEASE}-base-image
DEBIAN_WORKDIR=$HOME/debian-image-from-scratch
RAW_DEBIAN_IMAGE_PATH=${DEBIAN_WORKDIR}/debian-${DEBIAN_RELEASE}-image.raw

# Create the VM
vboxmanage createvm --name ${DEBIAN_BASE_IMAGE} --ostype Debian_64 --register

# Configure the VM hardware
vboxmanage modifyvm ${DEBIAN_BASE_IMAGE} --firmware efi
vboxmanage modifyvm ${DEBIAN_BASE_IMAGE} --memory 512 --ioapic on
vboxmanage modifyvm ${DEBIAN_BASE_IMAGE} --audio-driver none
vboxmanage modifyvm ${DEBIAN_BASE_IMAGE} --usbcardreader off
vboxmanage modifyvm ${DEBIAN_BASE_IMAGE} --keyboard ps2 --mouse ps2
vboxmanage modifyvm ${DEBIAN_BASE_IMAGE} --graphicscontroller vmsvga --vram 33
vboxmanage modifyvm ${DEBIAN_BASE_IMAGE} --nic1 nat
vboxmanage modifyvm ${DEBIAN_BASE_IMAGE} --rtcuseutc on

# Add the DVC Drive
vboxmanage storagectl ${DEBIAN_BASE_IMAGE} --name "IDE" --add ide --controller PIIX4
vboxmanage storageattach ${DEBIAN_BASE_IMAGE} --storagectl "IDE" --port 0 --device 0 --type dvddrive --medium emptydrive

# Add the SATA DISK
vboxmanage storagectl ${DEBIAN_BASE_IMAGE} --name "SATA" --add sata --controller IntelAHCI --portcount 1
# Prepare the raw disk image to use on VirtualBox VMs
vboxmanage convertfromraw "${RAW_DEBIAN_IMAGE_PATH}" "$HOME/VirtualBox VMs/${DEBIAN_BASE_IMAGE}/${DEBIAN_BASE_IMAGE}.vdi"
# Attach disk to base image VM
vboxmanage storageattach ${DEBIAN_BASE_IMAGE} --storagectl "SATA" --port 0 --device 0 --type hdd --medium "$HOME/VirtualBox VMs/${DEBIAN_BASE_IMAGE}/${DEBIAN_BASE_IMAGE}.vdi"
