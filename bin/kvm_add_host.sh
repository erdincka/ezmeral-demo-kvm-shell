#!/usr/bin/env bash

set -u # abort on undefined variable
set +x # enable(-)/disable(+) debug

source ./etc/kvm_config.sh

[ -d ${PROJECT_DIR} ] || fail "This should be run after creating the cluster"

usage(){
  echo 
	echo "Usage: $0 <type>"
  echo '''
  This script is provided to add extra nodes to the HPE Ezmeral Container Platform on this KVM host
  
  <type> is on of the following
  kubehost | epichost: 16-core 96GB memory
  gpuhost: 16-core 96GB memory with pci-passthrough device (gpu-device.xml)
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
  kubehost | epichost)
    vmname=$(get_name "host")
    echo "Creating ${vmname} as ${TYPE}"
    if [[ "${TYPE}" == "kubehost" ]]; then
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
  gpuhost)
    # # note that we are picking first available device here (head -n1), adjust as necessary
    busid=$(lspci -nn | grep -i nvidia | grep -Eo '^..:..\..' | head -n1)
    echo "using ${busid}"

    vmname=$(get_name "gpuhost")
    echo "Creating ${vmname}"
    ./bin/kvm_centos_vm.sh ${vmname} 16 $(expr 96 \* 1024) 512G "--host-device ${busid}" || fail "cannot create ${vmname}"
    sleep 30
    # echo "Starting NVidia driver installation"
    driver_file="NVIDIA-Linux-x86_64-450.80.02.run"
    [[ -f ${driver_file} ]] || curl -# -o ${PROJECT_DIR}/${driver_file} "https://us.download.nvidia.com/tesla/450.80.02/NVIDIA-Linux-x86_64-450.80.02.run"
    ip=$(get_ip_for_vm "${vmname}")
    scp -o StrictHostKeyChecking=no -i ${LOCAL_SSH_PRV_KEY_PATH} ${PROJECT_DIR}/${driver_file} centos@${ip}:~
    ${SSHCMD} -T centos@${ip} << ENDSSH
      chmod +x ${driver_file}
      sudo mkdir -p /nvidia
      sudo mv ${driver_file} /nvidia
      sudo yum update -y -q 
      sudo yum install -y -q kernel-devel kernel-headers gcc-c++ perl pciutils
      sudo yum install -y -q kernel-devel-\$(uname -r) kernel-headers-\$(uname -r)
      eval "cat <<EOF
blacklist nouveau
options nouveau modeset=0
EOF
      " | sudo tee /etc/modprobe.d/denylist-nouveau.conf > /dev/null
      sudo rmmod nouveau
      sudo dracut --force
      sudo reboot
ENDSSH
    sleep 60
    ${SSHCMD} -T centos@${ip} <<ENDSSH
      lsmod | grep nouveau
      cd /nvidia
      sudo ./${driver_file} -s
      [ $(nvidia-smi | grep "Tesla" | wc -l) -eq 1 ] || exit 1 # "Nvidia driver installation didn't work!"
      nvidia-modprobe -u -c=0
      sudo reboot
ENDSSH
    sleep 30
    echo "${vmname} installation completed, please add using GUI or provided worker add scripts"

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
