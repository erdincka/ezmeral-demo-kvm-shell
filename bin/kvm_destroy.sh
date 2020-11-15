#!/usr/bin/env bash

source ./etc/kvm_config.sh

if [[ -z ${VM_DIR} ]]
then
    fail "unkown vm folder"
fi

### Remove VMs
if [ -d ${VM_DIR} ]; then
    dir=($(ls -r ${VM_DIR}))
    for (( i = 0; i < ${#dir[@]}; ++i )); do
        {
            virsh destroy ${dir[i]} &>/dev/null
            virsh undefine ${dir[i]} &>/dev/null
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
