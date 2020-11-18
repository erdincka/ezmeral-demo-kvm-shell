#!/usr/bin/env bash

source ./etc/kvm_config.sh

set -u
set +x

# Input should be host definition from kvm_config.sh (name, cores, mem, datadisk_size, public_bridge)
NAME=${1}
CPUS=${2}
MEM=${3}
DATADISKSIZE=${4:-0}
PUBLIC_BR=${5:-""}

DISK1=${NAME}-disk1.qcow2
DISK2=${NAME}-disk2.qcow2
DISK3=${NAME}-disk3.qcow2
USER_DATA=user-data
META_DATA=meta-data
SSH_PUB_KEY=$(<${LOCAL_SSH_PUB_KEY_PATH})

CLOUD_INIT=$(eval "cat <<EOF
$(<./etc/cloud-init-template.yaml)
EOF
" 2> /dev/null)

# clean up
virsh destroy "${NAME}" &>/dev/null 
virsh undefine "${NAME}" &>/dev/null 
rm -rf "${VM_DIR}"/"${NAME}" # clean up existing files

mkdir -p "${VM_DIR}"/"${NAME}"
pushd "${VM_DIR}"/"${NAME}" > /dev/null
    echo "${CLOUD_INIT}" > ${USER_DATA}
    echo "instance-id: ${NAME}; local-hostname: ${NAME}" > ${META_DATA}
    genisoimage -output "${NAME}-ci.iso" -volid cidata -joliet -r ${USER_DATA} ${META_DATA} &>/dev/null || fail "geniso failed"
    qemu-img create -f qcow2 -F qcow2 -b "${CENTOS_IMAGE_FILE}" "${DISK1}" &>/dev/null || fail "img create failed"
    qemu-img resize "${DISK1}" 512G &>/dev/null || fail "img resize failed"
    if [[ "${DATADISKSIZE}" == "0" ]]
    then
        DATADISKS=""
    else
        qemu-img create -f qcow2 "${DISK2}" "${DATADISKSIZE}" &>/dev/null
        qemu-img create -f qcow2 "${DISK3}" "${DATADISKSIZE}" &>/dev/null
        DATADISKS="--disk ${DISK2},format=qcow2,bus=virtio --disk ${DISK3},format=qcow2,bus=virtio"
    fi
    if [[ "${PUBLIC_BR}" == "" ]]
    then
        PUBLICNET=""
    else
        PUBLICNET="--network bridge=${PUBLIC_BR}"
    fi

    virt-install \
        --import \
        --name ${NAME} \
        --memory ${MEM} \
        --vcpus ${CPUS} \
        --disk "${DISK1}",format=qcow2,bus=virtio ${DATADISKS} \
        --disk "${NAME}-ci.iso",device=cdrom \
        --network bridge="${BRIDGE}",model=virtio ${PUBLICNET} \
        --os-type Linux \
        --os-variant centos7.0 \
        --noautoconsole &>/dev/null || fail "virt-install failed"

    MAC=$(sudo virsh dumpxml ${NAME} | awk -F\' '/mac address/ {print $2}' | head -n 1)
    
    # echo -n "Waiting for IP "
    while true
    do
        IP=$(grep -B1 $MAC /var/lib/libvirt/dnsmasq/"${BRIDGE}".status | head \
             -n 1 | awk '{print $2}' | sed -e s/\"//g -e s/,//)
        if [ "$IP" = "" ]
        then
            sleep 2
            # echo -n '.'
        else
            break
        fi
    done

    # Eject cdrom
    virsh change-media "${NAME}" sda --eject --config &>/dev/null
    # Remove the cloud init file
    rm -f "${META_DATA}" "${USER_DATA}" "${NAME}-ci.iso" &>/dev/null
    # set autostart at boot
    virsh autostart ${NAME} &>/dev/null 
    # completed
    # echo "${NAME} ready at: ssh -i ${LOCAL_SSH_PRV_KEY_PATH} -o StrictHostKeyChecking=no centos@${IP:-noIP}"

popd > /dev/null

exit 0
