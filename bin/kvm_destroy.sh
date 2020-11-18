#!/usr/bin/env bash

source ./etc/kvm_config.sh

[[ ! -z ${VM_DIR} ]] || fail "unkown vm folder"

# Delete gateway forwarding rules
sudo iptables -D FORWARD -o ${BRIDGE} -p tcp -d ${GATW_PRV_IP} --dport 10000:50000 -j ACCEPT
sudo iptables -D FORWARD -o ${BRIDGE} -p tcp -d ${GATW_PRV_IP} --dport 22 -j ACCEPT
sudo iptables -t nat -D PREROUTING -p tcp --dport 10000:50000 -j DNAT --to ${GATW_PRV_IP}
sudo iptables -t nat -D PREROUTING -p tcp --dport 7222 -j DNAT --to ${GATW_PRV_IP}:22


### Remove VMs
if [ -d ${VM_DIR} ]; then
    dir=($(ls -r ${VM_DIR}))
    for (( i = 0; i < ${#dir[@]}; ++i )); do
        {
            vm=${dir[i]}
            # clean from auth cache
            ssh-keygen -f "${HOME}/.ssh/known_hosts" -R "$(get_ip_for_vm ${vm})" &>/dev/null
            virsh destroy ${vm} &>/dev/null
            virsh undefine ${vm} &>/dev/null
        } &
    done
    wait # for all VMs to be destroyed
    rm -rf ${VM_DIR} &>/dev/null
fi

if [ -d "${OUT_DIR}" ]; then
    pushd "${OUT_DIR}" > /dev/null
        rm -f bluedata_install_output.txt* get_public_endpoints.sh ssh_*.sh hpecp_cli.log hpecp.conf
    popd > /dev/null
    [ -f etc/postcreate.sh.completed ] && rm etc/postcreate.sh.completed
fi

# Clean downloaded scripts and other generated files too
if [[ "${1}" == "all" ]]; then
    echo "cleaning downloaded scripts"
    pushd ./scripts > /dev/null
        rm -rf end_user_scripts check_prerequisites.sh functions.sh bluedata_install.sh \
            post_refresh_or_apply.sh mapr_install.sh mapr_update.sh verify_ad_server_config.sh 
        pushd ./ad_files > /dev/null
            rm -f ad_set_posix_classes.ldif ad_user_setup.sh ldif_modify.sh run_ad.sh
        popd > /dev/null
        rm -rf ./ad_files
    popd > /dev/null
    pushd ./etc > /dev/null
        rm -f postcreate.sh postcreate.sh.completed hpecp_cli_logging.conf
    popd > /dev/null
    pushd ./bin > /dev/null
        rm -rf df-cluster-acl-ad_admin1.sh experimental
    popd > /dev/null
    if [ -d "${OUT_DIR}" ]; then
        pushd "${OUT_DIR}" > /dev/null
            rm -f hpecp_cli_logging.conf bluedata_infra_variables.tf \
                ca-cert.pem ca-key.pem cert.pem controller.prv_key controller.pub_key hpecp.conf key.pem 
        popd > /dev/null
    fi    
fi

exit 0
