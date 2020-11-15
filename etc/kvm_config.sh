#!/usr/bin/env bash

# VM Network
DOMAIN="ecp.demo"
# KVM_NETWORK="sriov-net"
# NET=10.1.10
# BRIDGE=$(virsh net-info default | grep -e ^Bridge: | awk '{ print $2 }')

# Gateway network
PUBLIC_DOMAIN=garage.dubai
#PUBLIC_BRIDGE="eno5v1"
GATW_PUB_IP=10.1.1.22
GATW_PUB_GW=10.1.1.1
GATW_PUB_MASK=255.255.255.0
GATW_PUB_HOST=ecp
GATW_PUB_DNS="${GATW_PUB_HOST}.${PUBLIC_DOMAIN}"
AD_SERVER_ENABLED=True

# Host resources (cores, mem, data disk)
# controller=(16, 64G, 512G)
# gw=(8, 32G, 0G)
# host1=(16, 64G, 512G)
# host2=(16, 64G, 512G)
# host3=(12, 64G, 512G)
# if [[ "${AD_SERVER_ENABLED}" == "True" ]]; then
#     ad=(4, 8G, 0G)
# fi
# hosts=(controller, gw, host1, host2, host3, ad)

# Local settings
TIMEZONE="Asia/Dubai"
CENTOS_IMAGE_FILE="/data/CentOS-7-x86_64-GenericCloud-2003.qcow2"
EPIC_FILENAME="hpe-cp-rhel-release-5.1-3011.bin"
EPIC_DL_URL="/data/${EPIC_FILENAME}"

CREATE_EIP_CONTROLLER=False
CREATE_EIP_GATEWAY=True

INSTALL_WITH_SSL=True

PROJECT_DIR=/data/ecp
VM_DIR="${PROJECT_DIR}"/vms
OUT_DIR="${PROJECT_DIR}"/generated
HOSTS_FILE="${OUT_DIR}"/hosts
CA_KEY="${OUT_DIR}/ca-key.pem"
CA_CERT="${OUT_DIR}/ca-cert.pem"
LOCAL_SSH_PUB_KEY_PATH="${OUT_DIR}/controller.pub_key"
LOCAL_SSH_PRV_KEY_PATH="${OUT_DIR}/controller.prv_key"

HOST_INTERFACE=$(ip route show default | head -1 | cut -d' ' -f5)
CLIENT_CIDR_BLOCK=$(ip a s dev ${HOST_INTERFACE} | awk /'inet / { print $2 }' | head -n1)
VPC_CIDR_BLOCK=$CLIENT_CIDR_BLOCK
REGION=ME
EPIC_OPTIONS='--skipeula'
WGET_OPTIONS=""

EPIC_DL_URL_NEEDS_PRESIGN=False
SELINUX_DISABLED=True
MAPR_CLUSTER1_COUNT=0 
MAPR_CLUSTER2_COUNT=0 
RDP_SERVER_ENABLED=False
RDP_SERVER_OPERATING_SYSTEM="LINUX"
CREATE_EIP_RDP_LINUX_SERVER=False

# Helper functions
function fail {
   echo "${1}"
   exit 1
}
