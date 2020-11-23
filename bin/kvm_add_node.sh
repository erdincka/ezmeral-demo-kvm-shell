#!/usr/bin/env bash

set -u # abort on undefined variable
set +x # enable(-)/disable(+) debug

source ./etc/kvm_config.sh

[ -d ${PROJECT_DIR} ] || fail "This should be run after creating the cluster"

usage(){
	echo "Usage: $0 <type>"
  echo '''
  This script is provided to add extra nodes to the HPE Ezmeral Container Platform on this KVM host
  
  <type>
  kubenode | epicnode: 16-core 96GB memory
  gpunude: 16-core 96GB memory with pci-passthrough device (gpu-device.xml)
  gateway: 8-core 24GB memory
  controller: 16-core 96GB memory

  '''
	exit 1
}

[[ $# -eq 0 ]] && usage

TYPE=${1}

get_name() {
  # find the last num for given hostname if there is any digit at the end of vm name
  lastnum=$(virsh list --all --name | grep ${1} | sort | tail -n1 | grep -o '[[:digit:]]*$')
  # return the name with incremented no
  echo "${1}`expr ${lastnum} + 1`"
}

case ${TYPE} in
  kubenode | epicnode)
    vmname=$(get_name "host")
    echo "Creating ${vmname} as ${TYPE}"
    if [[ "${TYPE}" == "kubenode" ]]; then
      ./bin/kvm_centos_vm.sh ${vmname} 16 $(expr 96 \* 1024) 512G || fail "cannot create ${vmname}"
      # sleep 60
      # ip=$(get_ip_for_vm ${vmname})
      # [ ! -z ${ip} ] && ./bin/experimental/03_k8sworkers_add.sh "${ip}"
    else
      ./bin/kvm_centos_vm.sh ${vmname} 12 $(expr 96 \* 1024) 512G || fail "cannot create ${vmname}"
      # sleep 60
      # ip=$(get_ip_for_vm ${vmname})
      # [ ! -z ${ip} ] && ./bin/experimental/epic_workers_add.sh "${ip}"
    fi
    ;;
  gpunode)
    # ref: https://www.server-world.info/en/note?os=Ubuntu_18.04&p=kvm&f=11
    # first check if we can do passthrough
    [[ -z "$(dmesg | grep 'IOMMU enabled')" ]] && fail "IOMMU not enabled in kernel"
    
    # note that we are picking first available device here (head -n1), adjust as necessary
    pciid=$(lspci -nn | grep -i nvidia | grep -Eo '\[....:....\]' | sed "s/^\[//g" | sed "s/\]$//" | head -n1)
    [[ -z ${pciid} ]] && fail "can't find any nvidia device"
    
    # check if device passed to vfio, add modprobe if not (requires reboot)
    busid=$(lspci -nn | grep -i nvidia | grep -Eo '^..:..\..' | head -n1)
    [[ -z "$(dmesg | grep -i vfio | grep ${busid})" ]] && echo "options vfio-pci ids=${pciid}" | \
      sudo tee -a /etc/modprobe.d/vfio.conf > /dev/null && fail "VFIO was not enabled, reboot required"
    echo "using ${busid}"
#     GPU_DEVICE_FILE=$(mktemp)
#     trap '{ rm -f $GPU_DEVICE_FILE; }' EXIT
#     cat > ${GPU_DEVICE_FILE} <<- EOB
# <hostdev mode='subsystem' type='pci' managed='yes'>
#   <source>
#     <address domain='0x0000' bus="0x${busid:0:2}" slot="0x${busid:3:2}" function="0x${busid:6:1}"/>
#   </source>
# </hostdev>
# EOB

    vmname=$(get_name "gpuhost")
    echo "Creating ${vmname}"
    ./bin/kvm_centos_vm.sh ${vmname} 16 $(expr 96 \* 1024) 512G "--host-device ${busid}" || fail "cannot create ${vmname}"
    # sleep 30
    # virsh attach-device 
    ;;
  gateway)
    vmname=$(get_name "gateway")
    echo "Creating ${vmname}"
    ./bin/kvm_centos_vm.sh ${vmname} 8 $(expr 16 \* 1024) || fail "cannot create gateway"
    ;;
  controller)
    vmname=$(get_name "controller")
    echo "Creating ${vmname}"
    ./bin/kvm_centos_vm.sh ${vmname} 16 $(expr 96 \* 1024) 512G || fail "cannot create controller"
    ;;
  mapr)
    fail "Don't know how to do it yet"
    ;;
  *)
    fail "Unknown node type"
    ;;
esac

exit 0 
