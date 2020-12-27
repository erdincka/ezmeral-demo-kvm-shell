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
  gpuhost: 16-core 96GB memory with pci-passthrough device (passthrough-device.xml)
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
    else
      ./bin/kvm_centos_vm.sh ${vmname} 12 $(expr 96 \* 1024) 512G || fail "cannot create ${vmname}"
    fi
    ;;
  gpuhost)
    # # note that we are picking first available device here (head -n1), adjust as necessary
    busids=$(lspci -nn | grep -i nvidia | grep -Eo '^..:..\..' | xargs)
    device_str=""
    for busid in ${busids[@]}; do
      device_str+="--host-device ${busid} "
    done
    echo "Attaching GPU(s) at ${busids}"
    vmname=$(get_name "gpuhost")
    echo "Creating ${vmname}"
    ./bin/kvm_centos_vm.sh ${vmname} 16 $(expr 96 \* 1024) 512G "${device_str}" || fail "cannot create ${vmname}"
    sleep 5
    ip=$(get_ip_for_vm "${vmname}")
    echo -n "Connecting to ${ip}"
    wait_for_ssh "${ip}"
    driver_file="NVIDIA-Linux-x86_64-450.80.02.run"
    [[ -f ${driver_file} ]] || curl -# -o ${PROJECT_DIR}/${driver_file} "https://us.download.nvidia.com/tesla/450.80.02/NVIDIA-Linux-x86_64-450.80.02.run"
    scp -o StrictHostKeyChecking=no -i ${LOCAL_SSH_PRV_KEY_PATH} ${PROJECT_DIR}/${driver_file} centos@${ip}:~
    echo "pre-configuration for GPU (might take a while)"
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
    wait_for_ssh "${ip}"
    echo "post-configuration for GPU"
    ${SSHCMD} -T centos@${ip} <<ENDSSH
      [ $(lsmod | grep nouveau | wc -l) -eq 0 ] || echo "conflicting video driver - nouveau"
      cd /nvidia
      sudo ./${driver_file} -s
      [ $(nvidia-smi | grep "Tesla" | wc -l) -ne 0 ] || echo "Nvidia driver installation failed"
      nvidia-modprobe -u -c=0
      sudo reboot
ENDSSH
    echo "wait until ${vmname} becomes ready"
    wait_for_ssh "${ip}"
    echo "${vmname} installation completed, please add using GUI or provided worker add scripts"
    echo "${SSHCMD} centos@${ip}" > "${OUT_DIR}/ssh_${vmname}.sh"
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
    usage
    ;;
esac

exit 0 
