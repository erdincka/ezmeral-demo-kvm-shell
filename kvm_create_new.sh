#!/usr/bin/env bash

set -u # abort on undefined variable
set +x # enable debug

source ./etc/kvm_config.sh

echo "Checking scripts"
./bin/kvm_collect_scripts_from_github.sh || fail "unable to collect required scripts"
source ./scripts/functions.sh 

echo "Checking host prerequisites"
./scripts/check_prerequisites.sh || fail "pre-requisites failed for host"

# checking network
is_domainset=$(virsh net-dumpxml ${KVM_NETWORK} | grep ${DOMAIN})
if [ -z "${is_domainset}" ]
then
   echo "Ensure your network set up properly for ${KVM_NETWORK}"
   echo "You can configure recommended settings with ./bin/kvm_prepare_network.sh (edit before use)"
   echo "You need <domain name='${DOMAIN}' localOnly='yes'/> in your NAT network configuration (edit with virsh net-edit ${KVM_NETWORK}"
   echo "And restart libvirtd.service (sudo systemctl restart libvirtd.service)"
   exit 1
fi

is_netactive=$(virsh net-info ${KVM_NETWORK} | grep -e ^Active: | awk '{ print $2 }')
if [[ "${is_netactive}" != "yes" ]]
then
   echo "Starting ${KVM_NETWORK}"
   sudo virsh net-start ${KVM_NETWORK}
else
   echo "Using ${KVM_NETWORK} network"
fi

# create directories
[[ -d "${PROJECT_DIR}" ]] || (sudo mkdir -p ${PROJECT_DIR} && sudo chown -R ${USER} ${PROJECT_DIR})
[[ -d "${OUT_DIR}" ]] || mkdir -p ${OUT_DIR}
[[ -d ./generated ]] || ln -s ${OUT_DIR} ./generated

# Need the key pair for paswordless login
if [[ ! -f  "${LOCAL_SSH_PRV_KEY_PATH}" ]]; then
   echo "Setting up private/public keys"
   ssh-keygen -m pem -t rsa -N "" -f "${LOCAL_SSH_PRV_KEY_PATH}" &>/dev/null
   mv "${LOCAL_SSH_PRV_KEY_PATH}.pub" "${LOCAL_SSH_PUB_KEY_PATH}"
   chmod 600 "${LOCAL_SSH_PRV_KEY_PATH}"
fi

# create VMs
echo "Deploying VMs"
./bin/kvm_centos_vm.sh controller 16 65536 512G || fail "cannot create controller" &
./bin/kvm_centos_vm.sh gtwy 8 32768 || fail "cannot create gateway" &
# 2 hosts for K8s and 1 for EPIC
./bin/kvm_centos_vm.sh host1 16 65536 512G || fail "cannot create host1" &
./bin/kvm_centos_vm.sh host2 16 65536 512G || fail "cannot create host2" &
./bin/kvm_centos_vm.sh host3 12 65536 512G || fail "cannot create host3" &

if [[ "${AD_SERVER_ENABLED}" == "True" ]]; then
   ./bin/kvm_centos_vm.sh ad 4 8192 || fail "cannot create ad" &
fi

wait # for all VMs to be ready

{
   if [ "${CREATE_EIP_GATEWAY}" == "True" ]; then
      echo "Setting gateway public IP"
      sleep 5 # wait for IP to be assigned
      virsh attach-device gtwy ./etc/passthrough_device.xml
      # setsebool -P virt_use_sysfs 1 &>/dev/null # in case needed for CentOS/RHEL
      IFCFG=$(eval "cat <<EOF
      $(<./etc/ifcfg-eth1.template)
EOF
      " 2> /dev/null)
      echo "$IFCFG"
      echo "al sana amk"
      source ./scripts/variables.sh # update private ip
      ${SSHCMD} -T centos@${GATW_PRV_IP} <<ENDSSH
         # sudo yum install -y -q NetworkManager &>/dev/null
         # sudo systemctl start NetworkManager &>/dev/null
         # sudo nmcli connection add type ethernet con-name eth1 ifname eth1 ip4 ${GATW_PUB_IP}/24
         # sudo nmcli con up eth1 ifname eth1 
         echo "$IFCFG" | sudo tee /etc/sysconfig/network-scripts/ifcfg-eth1
         echo "eth1 configuration updated with"
         echo "$IFCFG"
         sudo systemctl restart network
         echo "public ip is available"
ENDSSH
   fi
} &

{
if [[ "${AD_SERVER_ENABLED}" == "True" ]]; then
   echo "Setting up AD, please wait"
   sleep 5
   scp -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T \
      ./scripts/ad_files/* centos@$(get_ip_for_vm "ad"):~/ &>/dev/null
   ${SSHCMD} -T centos@$(get_ip_for_vm "ad") &>/dev/null <<EOT
      ### Hack to avoid same run each time with updates, possibly should move to post create
      [ -f ad_set_posix_classes.log ] && exit 0
      set -ex
      sudo yum install -y -q docker openldap-clients &>/dev/null 
      sudo service docker start &>/dev/null 
      sudo systemctl enable docker &>/dev/null 
      . /home/centos/run_ad.sh &>/dev/null
      sleep 120
      . /home/centos/ldif_modify.sh
EOT
   echo "AD configured"
fi
} &
wait # for updated VMs

print_header "Running ./scripts/post_refresh_or_apply.sh"
./scripts/post_refresh_or_apply.sh

print_header "Installing HCP"
./scripts/bluedata_install.sh

print_header "Installing HPECP CLI on Controller"
./bin/experimental/install_hpecp_cli.sh 

# print_header "Installing demo apps (spark23 and spark24) onto controller from local repo"
# ./scripts/kvm_upload_demo_apps.sh

if [[ -f ./etc/postcreate.sh ]]; then
   print_header "Found ./etc/postcreate.sh so executing it"
   ./etc/postcreate.sh && mv ./etc/postcreate.sh ./etc/postcreate.sh.completed
else
   print_header "./etc/postcreate.sh not found - skipping."
fi

cat > "${OUT_DIR}"/get_public_endpoints.sh <<EOF

Controller: ${SSHCMD} centos@$(get_ip_for_vm controller)
Gateway: ${SSHCMD} centos@$(get_ip_for_vm gtwy)
AD: ${SSHCMD} centos@$(get_ip_for_vm ad)
Host1: ${SSHCMD} centos@$(get_ip_for_vm host1)
Host2: ${SSHCMD} centos@$(get_ip_for_vm host2)
Host3: ${SSHCMD} centos@(get_ip_for_vm host3)

EOF

echo "${SSHCMD} centos@$(get_ip_for_vm controller) \$1" > "${OUT_DIR}"/ssh_controller.sh
echo "${SSHCMD} centos@$(get_ip_for_vm gtwy) \$1" > "${OUT_DIR}"/ssh_gateway.sh
echo "${SSHCMD} centos@$(get_ip_for_vm ad) \$1" > "${OUT_DIR}"/ssh_ad.sh
echo "${SSHCMD} centos@$(get_ip_for_vm host1) \$1" > "${OUT_DIR}"/ssh_host1.sh
echo "${SSHCMD} centos@$(get_ip_for_vm host2) \$1" > "${OUT_DIR}"/ssh_host2.sh
echo "${SSHCMD} centos@(get_ip_for_vm host3) \$1" > "${OUT_DIR}"/ssh_host3.sh
chmod +x "${OUT_DIR}"/*.sh

print_term_width '-'
echo "Run "${OUT_DIR}"/get_public_endpoints.sh for all connection details."
print_term_width '-'

print_term_width '='

exit 0
