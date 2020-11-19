#!/usr/bin/env bash

set -e # abort on error
set -u # abort on undefined variable

# disable '-x' because it is too verbose for this script
# and is not useful for this script
if [[ $- == *x* ]]; then
  was_x_set=1
else
  was_x_set=0
fi

source ./scripts/functions.sh
source ./etc/kvm_config.sh

if [[ "${AD_SERVER_ENABLED}" == "True" ]]; then
   AD_PRV_IP=$(get_ip_for_vm "ad")
   AD_PUB_IP=$AD_PRV_IP
fi

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
[ "$PROJECT_DIR" ] || ( echo "ERROR: PROJECT_DIR is empty" && exit 1 )

LOG_FILE="${OUT_DIR}"/bluedata_install_output.txt
[[ -f "$LOG_FILE" ]] && mv -f "$LOG_FILE" "${LOG_FILE}".old

# Verify if all variables are set correctly
[ "$CA_KEY" ] || ( echo "ERROR: CA_KEY is empty" && exit 1 )
[ "$CA_CERT" ] || ( echo "ERROR: CA_CERT is empty" && exit 1 )

[ "$EPIC_DL_URL" ] || ( echo "ERROR: EPIC_DL_URL is empty" && exit 1 )
[ "$EPIC_FILENAME" ] || ( echo "ERROR: EPIC_FILENAME is empty" && exit 1 )

[ "${SELINUX_DISABLED}" ] || ( echo "ERROR: SELINUX_DISABLED is empty" && exit 1 )

CTRL_PRV_IP=$(get_ip_for_vm "controller")
CTRL_PRV_HOST="controller"
CTRL_PRV_DNS=${CTRL_PRV_HOST}.${DOMAIN}
if [ "${CREATE_EIP_CONTROLLER}" == "False" ]; then
   CTRL_PUB_IP=${CTRL_PRV_IP}
   CTRL_PUB_HOST=${CTRL_PRV_HOST}
   CTRL_PUB_DNS=${CTRL_PRV_DNS}
fi

### TODO: refactor this checks below to a method

[ "$CTRL_PRV_IP" ] || {
   echo "***********************************************************************************"
   echo "ERROR: CTRL_PRV_IP is empty - is the instance running?"
   echo
   echo "***********************************************************************************"
   exit 1 
}

[ "$CTRL_PUB_IP" ] || {
   echo "***********************************************************************************"
   echo "ERROR: CTRL_PUB_IP is empty - is the  instance running?"
   echo
   echo "***********************************************************************************"
   exit 1 
}

[ "$CTRL_PRV_DNS" ] || {
   echo "***********************************************************************************"
   echo "ERROR: CTRL_PRV_DNS is empty - is the  instance running?"
   echo
   # echo "       You can check instance status with: ./generated/cli_running__instances.sh"
   # echo "       You can start instances with: ./generated/cli_start__instances.sh"
   echo "***********************************************************************************"
   exit 1 
}

[ "$CTRL_PUB_DNS" ] || {
   echo "***********************************************************************************"
   echo "ERROR: CTRL_PUB_DNS is empty - is the  instance running?"
   echo
   # echo "       You can check instance status with: ./generated/cli_running__instances.sh"
   # echo "       You can start instances with: ./generated/cli_start__instances.sh"
   echo "***********************************************************************************"
   exit 1 
}

[ "$CTRL_PUB_HOST" ] || {
   echo "***********************************************************************************"
   echo "ERROR: CTRL_PUB_HOST is empty - is the  instance running?"
   echo
   # echo "       You can check instance status with: ./generated/cli_running__instances.sh"
   # echo "       You can start instances with: ./generated/cli_start__instances.sh"
   echo "***********************************************************************************"
   exit 1 
}

[ "$CTRL_PRV_HOST" ] || {
   echo "***********************************************************************************"
   echo "ERROR: CTRL_PRV_HOST is empty - is the  instance running?"
   echo
   # echo "       You can check instance status with: ./generated/cli_running__instances.sh"
   # echo "       You can start instances with: ./generated/cli_start__instances.sh"
   echo "***********************************************************************************"
   exit 1 
}

GATW_PRV_IP=$(get_ip_for_vm "gtwy")
GATW_PRV_HOST="gtwy"
GATW_PRV_DNS=${GATW_PRV_HOST}.${DOMAIN}
if [ "${CREATE_EIP_GATEWAY}" == "False" ]; then
   GATW_PUB_IP=$GATW_PRV_IP
   GATW_PUB_HOST=$GATW_PRV_HOST
   GATW_PUB_DNS=$GATW_PRV_DNS
fi

function set_iptables {
   sudo iptables -I FORWARD -o ${BRIDGE} -p tcp -d ${GATW_PRV_IP} --dport 10000:50000 -j ACCEPT 
   sudo iptables -I FORWARD -o ${BRIDGE} -p tcp -d ${GATW_PRV_IP} --dport 22 -j ACCEPT 
   sudo iptables -t nat -I PREROUTING -p tcp --dport 10000:50000 -j DNAT --to ${GATW_PRV_IP} 
   sudo iptables -t nat -I PREROUTING -p tcp --dport 7222 -j DNAT --to ${GATW_PRV_IP}:22 
   echo "nat rules updated"
}

[ "$GATW_PRV_IP" ] || ( echo "ERROR: GATW_PRV_IP is empty - is the instance running?" && exit 1 )
[ "$GATW_PUB_IP" ] || ( echo "ERROR: GATW_PUB_IP is empty - is the instance running?" && exit 1 )
[ "$GATW_PRV_DNS" ] || ( echo "ERROR: GATW_PRV_DNS is empty - is the instance running?" && exit 1 )
[ "$GATW_PUB_DNS" ] || ( echo "ERROR: GATW_PUB_DNS is empty - is the instance running?" && exit 1 )
[ "$GATW_PUB_HOST" ] || ( echo "ERROR: GATW_PUB_HOST is empty - is the instance running?" && exit 1 )
[ "$GATW_PRV_HOST" ] || ( echo "ERROR: GATW_PRV_HOST is empty - is the instance running?" && exit 1 )

# WORKER_COUNT=$(grep -c "host" "${HOSTS_FILE}")

WRKR_PRV_IPS=( $(get_ip_for_vm "host1") $(get_ip_for_vm "host2") $(get_ip_for_vm "host3") )
WRKR_PUB_IPS=${WRKR_PRV_IPS[@]}

if [[ "$MAPR_CLUSTER1_COUNT" == "3" ]]; then
   MAPR_CLUSTER1_HOSTS_PRV_IPS =$( get_ip_for_vm "mapr1" get_ip_for_vm "mapr2" get_ip_for_vm "mapr3" )
   read -r -a MAPR_CLUSTER1_HOSTS_PRV_IPS <<< "$MAPR_CLUSTER1_HOSTS_PRV_IPS"
   read -r -a MAPR_CLUSTER1_HOSTS_PUB_IPS <<< "$MAPR_CLUSTER1_HOSTS_PUB_IPS"
else
   MAPR_CLUSTER1_HOSTS_PRV_IPS=()
   MAPR_CLUSTER1_HOSTS_PUB_IPS=()
fi

if [[ "$MAPR_CLUSTER2_COUNT" == "3" ]]; then
   MAPR_CLUSTER2_HOSTS_PRV_IPS =$( get_ip_for_vm "mapr4" get_ip_for_vm "mapr5" get_ip_for_vm "mapr6" )
   read -r -a MAPR_CLUSTER2_HOSTS_PRV_IPS <<< "$MAPR_CLUSTER2_HOSTS_PRV_IPS"
   read -r -a MAPR_CLUSTER2_HOSTS_PUB_IPS <<< "$MAPR_CLUSTER2_HOSTS_PUB_IPS"
else
   MAPR_CLUSTER2_HOSTS_PRV_IPS=()
   MAPR_CLUSTER2_HOSTS_PUB_IPS=()
fi

if [[ $was_x_set == 1 ]]; then
   set -x
else
   set +x
fi 