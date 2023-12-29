#!/bin/bash
set -x
set -e

DEBIAN_RELEASE=bookworm
DEBIAN_BASE_VM=debian-${DEBIAN_RELEASE}-base-vm
DEBIAN_WORKDIR=debian-image-from-scratch
RAW_DEBIAN_IMAGE_PATH=~/${DEBIAN_WORKDIR}/debian-${DEBIAN_RELEASE}-image.raw

# Create the VM
vboxmanage createvm --name ${DEBIAN_BASE_VM} --ostype Debian_64 --register

# Configure the VM hardware
vboxmanage modifyvm ${DEBIAN_BASE_VM} --memory 512 --ioapic on
vboxmanage modifyvm ${DEBIAN_BASE_VM} --audio none
vboxmanage modifyvm ${DEBIAN_BASE_VM} --usbcardreader off
vboxmanage modifyvm ${DEBIAN_BASE_VM} --keyboard ps2 --mouse ps2
vboxmanage modifyvm ${DEBIAN_BASE_VM} --graphicscontroller vmsvga --vram 33
vboxmanage modifyvm ${DEBIAN_BASE_VM} --nic1 nat
vboxmanage modifyvm ${DEBIAN_BASE_VM} --rtcuseutc on
vboxmanage storagectl ${DEBIAN_BASE_VM} --name "IDE" --add ide --controller PIIX4
vboxmanage storagectl ${DEBIAN_BASE_VM} --name "SATA" --add sata --controller IntelAHCI --portcount 1
vboxmanage storageattach ${DEBIAN_BASE_VM} --storagectl "IDE" --port 0 --device 0 --type dvddrive --medium emptydrive

# Prepare the raw disk image to use on VirtualBox VMs
vboxmanage convertfromraw ${RAW_DEBIAN_IMAGE_PATH} "$HOME/VirtualBox VMs/${DEBIAN_BASE_VM}/${DEBIAN_BASE_VM}.vdi"

# Attach disk to base image VM
vboxmanage storageattach ${DEBIAN_BASE_VM} --storagectl "SATA" --port 0 --device 0 --type hdd --medium "$HOME/VirtualBox VMs/${DEBIAN_BASE_VM}/${DEBIAN_BASE_VM}.vdi"
