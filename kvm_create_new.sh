#!/usr/bin/env bash

set -u # abort on undefined variable
set +x # enable(-)/disable(+) debug

source ./etc/kvm_config.sh

# create directories
echo "Preparing project folder"
[[ -d "${PROJECT_DIR}" ]] || (sudo mkdir -p ${PROJECT_DIR} && sudo chown -R ${USER} ${PROJECT_DIR})
[[ -d "${OUT_DIR}" ]] || mkdir -p ${OUT_DIR}
[[ -d ./generated ]] || ln -s ${OUT_DIR} ./generated # if project_dir is different than current working dir
echo "Getting CentOS image file"
[[ -f "${PROJECT_DIR}"/"${CENTOS_FILENAME}" ]] || curl -# -o "${PROJECT_DIR}"/"${CENTOS_FILENAME}" "${CENTOS_DL_URL}"

# ensure pre-requisites are installed
echo "Using ${PKG_MANAGER} for installing missing packages"
if [[ ${PKG_MANAGER} == "yum" ]]; then 
   sudo yum install -q -y qemu-kvm libvirt libvirt-client virt-install python3 openssh nmap-ncat curl &>/dev/null
else
   sudo apt install -q -y qemu-kvm libvirt-daemon-system libvirt-clients virt-manager python3 python3-pip openssh-server &>/dev/null
fi
pip3 install --quiet --user ipcalc six hpecp &>/dev/null || fail "cannot update pip packages"

echo "Checking scripts"
./bin/kvm_collect_scripts_from_github.sh || fail "unable to collect required scripts"
source ./scripts/functions.sh 

echo "Checking host prerequisites"
./scripts/check_prerequisites.sh || fail "pre-requisites failed for host"

# checking network for ${DOMAIN} resolution
[ $(virsh net-dumpxml ${KVM_NETWORK} | grep ${DOMAIN} | wc -l) -eq 1 ] || fail '''
ERROR: VM network "'${KVM_NETWORK}'" not configured for local domain resolution
You can use recommended settings with ./bin/kvm_prepare_network.sh (edit before use) or use steps below.
- Edit net (virsh net-edit '${KVM_NETWORK}')
  - Add: <domain name="'${DOMAIN}'" localOnly="yes" />
- Destroy net (virsh net-destroy '${KVM_NETWORK}')
- Start net with new settings (virsh net-start '${KVM_NETWORK}')
- Restart service (sudo systemctl restart libvirtd.service)
'''

[[ $(virsh net-info ${KVM_NETWORK} | grep -e ^Active: | awk '{ print $2 }') == "yes" ]] && echo "Using ${KVM_NETWORK} network" || sudo virsh net-start ${KVM_NETWORK}

# Need the key pair for paswordless login
if [[ ! -f  "${LOCAL_SSH_PRV_KEY_PATH}" ]]; then
   echo "Setting up private/public keys"
   ssh-keygen -m pem -t rsa -N "" -f "${LOCAL_SSH_PRV_KEY_PATH}" &>/dev/null
   mv "${LOCAL_SSH_PRV_KEY_PATH}.pub" "${LOCAL_SSH_PUB_KEY_PATH}"
   chmod 600 "${LOCAL_SSH_PRV_KEY_PATH}"
fi

# create VMs
./bin/kvm_add_host.sh controller &
./bin/kvm_add_host.sh gateway &
./bin/kvm_add_host.sh kubehost &
# give time for vmname to be taken before
sleep 30 && ./bin/kvm_add_host.sh kubehost & 
sleep 60 && ./bin/kvm_add_host.sh epichost &

if [[ "${AD_SERVER_ENABLED}" == "True" ]]; then
   ./bin/kvm_centos_vm.sh ad 4 $(expr 8 \* 1024) || fail "cannot create ad" &
fi

wait # for all VMs to be ready

{
   if [ "${CREATE_EIP_GATEWAY}" == "True" ]; then
      echo "Setting gateway public IP"
      virsh attach-device gateway1 ./etc/passthrough_device.xml
      # setsebool -P virt_use_sysfs 1 &>/dev/null # in case needed for CentOS/RHEL
      IFCFG=$(eval "cat <<EOF
$(<./etc/ifcfg-eth1.template)
EOF
      " 2> /dev/null)
      sleep 30 && source ./scripts/variables.sh # update private ip
      ${SSHCMD} -T centos@${GATW_PRV_IP} &> /dev/null <<ENDSSH
         echo "$IFCFG" | sudo tee /etc/sysconfig/network-scripts/ifcfg-eth1 
         echo "DEFROUTE=no" | sudo tee -a /etc/sysconfig/network-scripts/ifcfg-eth0 
         echo 'interface "eth0" { supersede routers; }' | sudo tee -a /etc/dhcp/dhclient.conf 
         sudo systemctl restart network
ENDSSH
   fi
} &

{
if [[ "${AD_SERVER_ENABLED}" == "True" ]]; then
   echo "Setting up AD, might take a while"
   sleep 30 && source ./scripts/variables.sh # update private ip
   scp -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T \
      ./scripts/ad_files/* centos@${AD_PRV_IP}:~/ &>/dev/null
   ${SSHCMD} -T centos@${AD_PRV_IP} &> /dev/null <<EOT
      ### Hack to avoid same run each time with updates, possibly should move to post create
      [ -f ad_set_posix_classes.log ] && exit 0
      set -ex
      sudo yum install -y -q docker openldap-clients 
      sudo service docker start 
      sudo systemctl enable docker 
      . /home/centos/run_ad.sh 
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

if [[ -f ./etc/postcreate.sh ]]; then
   print_header "Found ./etc/postcreate.sh so executing it"
   date -R
   ./etc/postcreate.sh && mv ./etc/postcreate.sh ./etc/postcreate.sh.completed || fail "Fix issues before running ./etc/postcreate.sh script again"
   date -R
else
   print_header "./etc/postcreate.sh not found - skipping."
fi

cat > "${OUT_DIR}"/get_public_endpoints.sh <<EOF
cat <<EOE
Controller: ${SSHCMD} centos@$(get_ip_for_vm controller1)
Gateway: ${SSHCMD} centos@$(get_ip_for_vm gateway1)
AD: ${SSHCMD} centos@$(get_ip_for_vm ad)
Host1: ${SSHCMD} centos@$(get_ip_for_vm host1)
Host2: ${SSHCMD} centos@$(get_ip_for_vm host2)
Host3: ${SSHCMD} centos@$(get_ip_for_vm host3)

Alternatively you can ssh directly into hosts using ./generated/ssh_<hostname>.sh scripts.

EOE
EOF

echo "${SSHCMD} centos@$(get_ip_for_vm controller1) \$1" > "${OUT_DIR}"/ssh_controller1.sh
echo "${SSHCMD} centos@$(get_ip_for_vm gateway1) \$1" > "${OUT_DIR}"/ssh_gateway1.sh
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
