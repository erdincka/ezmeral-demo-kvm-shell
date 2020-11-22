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
    echo "Creating ${vmname}"
    ./bin/kvm_centos_vm.sh ${vmname} 16 $(expr 96 \* 1024) 512G || fail "cannot create ${vmname}"
    ./bin/kvm_centos_vm.sh ${vmname} 12 $(expr 96 \* 1024) 512G || fail "cannot create ${vmname}"
    ;;
  gpunode)
    vmname=$(get_name "gpuhost")
    echo "Creating ${vmname}"
    ./bin/kvm_centos_vm.sh ${vmname} 16 $(expr 96 \* 1024) 512G || fail "cannot create ${vmname}"
    sleep 10
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
