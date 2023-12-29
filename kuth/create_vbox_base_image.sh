#!/bin/bash

set -x
set -e

DEBIAN_BASE_IMAGE=debian-base-image

# Create the VM
vboxmanage createvm --name ${DEBIAN_BASE_IMAGE} --ostype Debian_64 --register

# Configure the VM hardware
vboxmanage modifyvm ${DEBIAN_BASE_IMAGE} --memory 512 --ioapic on

vboxmanage modifyvm ${DEBIAN_BASE_IMAGE} --audio none

vboxmanage modifyvm ${DEBIAN_BASE_IMAGE} --usbcardreader off

vboxmanage modifyvm ${DEBIAN_BASE_IMAGE} --keyboard ps2 --mouse ps2

vboxmanage modifyvm ${DEBIAN_BASE_IMAGE} --graphicscontroller vmsvga --vram 33

vboxmanage modifyvm ${DEBIAN_BASE_IMAGE} --nic1 nat

vboxmanage modifyvm ${DEBIAN_BASE_IMAGE} --rtcuseutc on

vboxmanage storagectl ${DEBIAN_BASE_IMAGE} --name "IDE" --add ide --controller PIIX4

vboxmanage storagectl ${DEBIAN_BASE_IMAGE} --name "SATA" --add sata --controller IntelAHCI --portcount 1

vboxmanage storageattach ${DEBIAN_BASE_IMAGE} --storagectl "IDE" --port 0 --device 0 --type dvddrive --medium emptydrive

# Prepare the raw disk image to use on VirtualBox VMs
vboxmanage convertfromraw ~/debian-image-from-scratch/debian-image.raw "$HOME/VirtualBox VMs/${DEBIAN_BASE_IMAGE}/${DEBIAN_BASE_IMAGE}.vdi"

# Attach disk to base image VM
vboxmanage storageattach ${DEBIAN_BASE_IMAGE} --storagectl "SATA" --port 0 --device 0 --type hdd --medium "$HOME/VirtualBox VMs/${DEBIAN_BASE_IMAGE}/${DEBIAN_BASE_IMAGE}.vdi"

