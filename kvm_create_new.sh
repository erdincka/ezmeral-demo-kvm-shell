#!/usr/bin/env bash

set -e # abort on error
set -u # abort on undefined variable
set +x # enable debug

source ./etc/kvm_config.sh

./bin/kvm_collect_scripts_from_github.sh

./scripts/check_prerequisites.sh

# create directories
[[ -d "${PROJECT_DIR}" ]] || (sudo mkdir -p ${PROJECT_DIR} && sudo chown -R ${USER} ${PROJECT_DIR})
[[ -d "${OUT_DIR}" ]] || mkdir -p ${OUT_DIR}

# Need the key pair for paswordless login
if [[ ! -f  "${LOCAL_SSH_PRV_KEY_PATH}" ]]; then
   ssh-keygen -m pem -t rsa -N "" -f "${LOCAL_SSH_PRV_KEY_PATH}"
   mv "${LOCAL_SSH_PRV_KEY_PATH}.pub" "${LOCAL_SSH_PUB_KEY_PATH}"
   chmod 600 "${LOCAL_SSH_PRV_KEY_PATH}"
fi

# verify network (using default network)
netactive=$(virsh net-info default | grep -e ^Active: | awk '{ print $2 }')
if [[ ${netactive} != 'yes' ]]
then
   sudo virsh net-start default
else
   echo 'Using default network'
fi

# create VMs
trap "wait" EXIT # ensure we wait for process completion on exit

./bin/kvm_centos_vm.sh ctrl 16 65536 512G || fail "cannot create controller" &

# For gateway I used SRIOV to provide networking, below is the script used to create that SRIOV pool (replace eno5 with your host device)
# Adjust to your specific KVM network, best choices to use are either Bridge or Passthrough networking to physical network
# ref: https://wiki.libvirt.org/page/Networking
#
# <network>
#    <name>sriov-net</name>
#    <uuid>46052a02-d6c0-429d-8f08-a0db0adda75b</uuid>
#    <forward mode='hostdev' managed='yes'>
#       <pf dev='eno5'/>
#       <address type='pci' domain='0x0000' bus='0x5d' slot='0x00' function='0x2'/>
#    </forward>
# </network>
#
# And vfio (sriov port mapping) requires non-root user access for /dev/vfio device tree
# edit and reload/restart udev device rules to change mapping
# edit file: /etc/udev/rules.d/10-qemu-hw-users.rules
#   add line: SUBSYSTEM=="vfio", OWNER="root", GROUP="kvm"
# or manually set group to kvm
#   sudo chgrp -R kvm /dev/vfio
# ref: https://www.evonide.com/non-root-gpu-passthrough-setup/
./bin/kvm_centos_vm.sh gw 8 32768 0 "sriov-net" || fail "cannot create gateway" &
# 2 hosts for K8s and 1 for EPIC
./bin/kvm_centos_vm.sh host1 16 65536 512G || fail "cannot create host1" &
./bin/kvm_centos_vm.sh host2 16 65536 512G || fail "cannot create host2" &
./bin/kvm_centos_vm.sh host3 12 65536 512G || fail "cannot create host3" &

if [[ "${AD_SERVER_ENABLED}" == "True" ]]; then
   ./bin/kvm_centos_vm.sh ad 4 8192 || fail "cannot create ad" &
fi

exit 0
