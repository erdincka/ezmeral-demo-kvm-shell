#!/usr/bin/env bash

# VM Network
DOMAIN="ecp.demo"
KVM_NETWORK="default"
BRIDGE=$(virsh net-info "${KVM_NETWORK}" | grep -e ^Bridge: | awk '{ print $2 }')

# Gateway network
# PUBLIC_BRIDGE="br-bond0"
PUBLIC_DOMAIN="garage.dubai"
GATW_PUB_IP="10.1.1.22"
GATW_PUB_GW="10.1.1.1"
GATW_PUB_PREFIX="24"
GATW_PUB_HOST="ecp"
GATW_PUB_DNS="${GATW_PUB_HOST}.${PUBLIC_DOMAIN}"
AD_SERVER_ENABLED="True"

# Local settings
TIMEZONE="Asia/Dubai"
CENTOS_FILENAME="CentOS-7-x86_64-GenericCloud-2003.qcow2"
CENTOS_DL_URL="http://10.1.1.202/files/osimages"/"${CENTOS_FILENAME}"
EPIC_FILENAME="hpe-cp-rhel-release-5.1-3011.bin"
EPIC_DL_URL="http://10.1.1.202/files/ezmeral/${EPIC_FILENAME}"

PROJECT_DIR="/data/ecp"
VM_DIR="${PROJECT_DIR}/vms"
OUT_DIR="${PROJECT_DIR}/generated"
HOSTS_FILE="${OUT_DIR}/hosts"
CA_KEY="${OUT_DIR}/ca-key.pem"
CA_CERT="${OUT_DIR}/ca-cert.pem"
LOCAL_SSH_PUB_KEY_PATH="${OUT_DIR}/controller.pub_key"
LOCAL_SSH_PRV_KEY_PATH="${OUT_DIR}/controller.prv_key"

#
# You probably don't need to touch these - haven't tested throughly
# These parameters are kept for compatibility with AWS scripts
# Please feel free to test and contribute to this project (pull requests are welcomed)
#
HOST_INTERFACE=$(ip route show default | head -1 | cut -d' ' -f5)
CLIENT_CIDR_BLOCK=$(ip a s dev ${HOST_INTERFACE} | awk /'inet / { print $2 }' | head -n1)
VPC_CIDR_BLOCK="${CLIENT_CIDR_BLOCK}
REGION="ME"
EPIC_OPTIONS='--skipeula'

CREATE_EIP_CONTROLLER="False"
CREATE_EIP_GATEWAY="True"

INSTALL_WITH_SSL="True"

EPIC_DL_URL_NEEDS_PRESIGN="False"
SELINUX_DISABLED="True"
MAPR_CLUSTER1_COUNT="0"
MAPR_CLUSTER2_COUNT="0"
RDP_SERVER_ENABLED="False"
RDP_SERVER_OPERATING_SYSTEM="LINUX"
CREATE_EIP_RDP_LINUX_SERVER="False"

# Helpers
SSHCMD="ssh -o StrictHostKeyChecking=no -i ${LOCAL_SSH_PRV_KEY_PATH}"

function fail {
   echo "ERROR: ${1}"
   [ ! -z ${2} ] && echo "RECOMMENDED: ${2}"
   exit 1
}

# ref: https://stackoverflow.com/a/54668619
function wait_for_ssh {
    until ${SSHCMD} -T centos@${1} true >/dev/null 2>&1; do 
        echo -n "."
        sleep 2
    done
}      

function get_ip_for_vm {
   echo -n $( echo $(virsh domifaddr ${1} --source agent | grep eth0 | head -n 1) | cut -d' ' -f 4 | cut -d'/' -f 1 )
}

# ref: https://unix.stackexchange.com/a/46086
declare -A osInfo;
osInfo[/etc/redhat-release]=yum
# osInfo[/etc/arch-release]=pacman
# osInfo[/etc/gentoo-release]=emerge
# osInfo[/etc/SuSE-release]=zypp
osInfo[/etc/debian_version]=apt

for f in ${!osInfo[@]}
do
    if [[ -f $f ]];then
        PKG_MANAGER=${osInfo[$f]}
    fi
done

# https://unix.stackexchange.com/a/225183
# function spinner {
#    PID=$!
#    i=1
#    sp="/-\|"
#    echo -n ' '
#    while [ -d /proc/$PID ]
#    do
#       sleep 0.5
#       printf "\b${sp:i++%${#sp}:1}"
#    done
# }
