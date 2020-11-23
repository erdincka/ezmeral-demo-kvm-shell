#!/usr/bin/env bash

set -u # abort on undefined variable
set +x # enable(-)/disable(+) debug

source ./etc/kvm_config.sh

# ref: https://www.server-world.info/en/note?os=Ubuntu_18.04&p=kvm&f=11
# first check if we can do passthrough
[[ -z "$(dmesg | grep 'IOMMU enabled')" ]] && fail "IOMMU not enabled in kernel"

# # note that we are picking first available device here (head -n1), adjust as necessary
pcidevid=$(lspci -nn | grep -i nvidia | grep -Eo '\[....:....\]' | sed "s/^\[//g" | sed "s/\]$//" | head -n1)
[[ -z ${pcidevid} ]] && fail "can't find any nvidia device"

# # check if device passed to vfio
busid=$(lspci -nn | grep -i nvidia | grep -Eo '^..:..\..' | head -n1)
[[ -z "$(dmesg | grep -i vfio | grep ${busid})" ]] && \
  echo "options vfio-pci ids=${pcidevid}" | sudo tee -a /etc/modprobe.d/vfio.conf > /dev/null && \
  echo 'vfio-pci' | sudo tee -a /etc/modules-load.d/vfio-pci.conf > /dev/null && \
  echo "blacklist nouveau" | sudo tee /etc/modprobe.d/denylist-nvidia-nouveau.conf && \
  echo "options nouveau modeset=0" | sudo tee -a /etc/modprobe.d/denylist-nvidia-nouveau.conf && \
  sudo rmmod nouveau && \
  echo "Enabling VFIO in kernel" && sudo update-initramfs -u && \
  fail "VFIO is now enabled, reboot required"
