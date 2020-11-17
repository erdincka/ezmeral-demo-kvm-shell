#!/usr/bin/env bash

### 
# This is a helper file to create virsh network
# 
# first param is network name to create, will use $KVM_NETWORK from kvm_config.sh if omitted
# second param is bridge name to attach, will use $KVM_NETWORK's bridge if omitted
#
### 

source "./etc/kvm_config.sh"

# Define network subnet (don't use CIDR like .0/24, it will be added automatically)
NET=10.1.10
NETWORK=${1:-${KVM_NETWORK}}
BRIDGE=${2:-${BRIDGE}}

echo Creating NAT network "${NETWORK}" on bridge "${BRIDGE}"

VIRTUAL_NET_XML_FILE=$(mktemp)
trap '{ rm -f $VIRTUAL_NET_XML_FILE; }' EXIT
cat > ${VIRTUAL_NET_XML_FILE} <<- EOB
<network>
    <name>${NETWORK}</name>
    <bridge name='${BRIDGE}' stp='on' delay='0'/>
    <forward mode="nat"/>
        <ip address="${NET}.1" netmask="255.255.255.0">
            <dhcp>
                <range start="${NET}.2" end="${NET}.254"/>
            </dhcp>
        </ip>
    <domain name='${DOMAIN}' localOnly='yes'/>
</network>
EOB

# Create network
sudo virsh net-define ${VIRTUAL_NET_XML_FILE}
sudo virsh net-start ${NETWORK}
sudo virsh net-autostart ${NETWORK}

# Enable IPv4 forwarding to/from virt-net
if [ $(grep -c "net.ipv4.ip.forward" /etc/sysctl.conf) = 0 ]; then
    echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
    echo "net.ipv4.conf.all.forwarding=1" | sudo tee -a /etc/sysctl.conf
    # sysctl -p
fi

# Following is needed if you want VM host names to be resolved in physical host
# echo "allow all" | sudo tee /etc/qemu-kvm/${USER}.conf > /dev/null
# echo "include /etc/qemu-kvm/${USER}.conf" | sudo tee --append /etc/qemu-kvm/bridge.conf
# sudo chown root:${USER} /etc/qemu-kvm/${USER}.conf
# sudo chmod 640 /etc/qemu-kvm/${USER}.conf
# Enable DNS resolution for virt-net
# netmanconf=$(cat <<EOF
# [main]
# dns=dnsmasq
# EOF
# )

# echo "${netmanconf}" | sudo tee /etc/NetworkManager/conf.d/localdns.conf > /dev/null

# # Set bridge interface IP as DNS server for virt-net
# dnsmasqconf=$(cat <<EOF
# server=/"${DOMAIN}"/${NET}.1
# EOF
# )
# echo "${dnsmasqconf}" | sudo tee /etc/NetworkManager/dnsmasq.d/libvirt_dnsmasq.conf > /dev/null

# # Update no_proxy to skip this net
# if [ "${BEHIND_PROXY}" == "True" ]
# then 
#     sudo sed -i "/^export no_proxy/ s/$/,.${DOMAIN},${NET}.0\/24/" ${SYSTEM_PROXY_FILE}
# fi

sudo systemctl restart NetworkManager
sudo systemctl restart libvirtd.service

exit 0
