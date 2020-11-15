# Deploy Ezmeral Container Platform on KVM

## What & Why
To re-utilize scripts and processes by https://github.com/hpe-container-platform-community/hcp-demo-env-aws-terraform/

## Pre-requisites
- CentOS/RHEL 7+ (tested on Ubuntu 20.04LTS Host)
- libvirt, qemu-kvm, libvirt-client, virt-manager
- Python3, openssh, nc, curl, ipcalc, hpecp
- Passwordless sudo

## Prepare environment
- KVM & Qemu
```shell
# Centos
sudo dnf install -y qemu-kvm libvirt libvirt-client
# Ubuntu
sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients
```
- virt-install
```shell
# Centos
sudo dnf install -y virt-install
# Ubuntu
sudo apt install -y virt-manager
```
- python3 & pip3
```shell
# Centos
sudo dnf install -y python3
# Ubuntu
sudo apt install -y python3 python3-pip
```
- ssh-keygen
```shell
# Centos
sudo dnf install -y openssh
# Ubuntu
sudo apt install -y openssh-server
```
- nc
```shell
# Centos
sudo dnf install -y nmap-ncat
# Ubuntu (installed by default)
```
- curl
```shell
# Centos
sudo dnf install -y curl
# Ubuntu (installed by default)
```
- ipcalc
```shell
pip3 install --user ipcalc six
```
- hpecp
```shell
pip3 install --user hpecp
```
- Edit sudoers file (for passwordless execution)
    - Centos: administrator user by default can do passwordless sudo
    - Ubuntu: https://linuxconfig.org/configure-sudo-without-password-on-ubuntu-20-04-focal-fossa-linux

### Collect and customize
```shell
git clone https://github.com/hpe-container-platform-community/hcp-demo-env-kvm-bash.git 
cd hcp-demo-env-kvm-bash
vi etc/kvm_config.sh
```

> <code>PROJECT_DIR=_this_</code>

> <code>CENTOS_IMAGE_FILE=_path-to-local CentOS-7-x86_64-GenericCloud-2003.qcow2_</code>

> <code>TIMEZONE=_your time zone in ?? format_ ie, "Asia/Dubai"</code>

> <code>EPIC_FILENAME="path-to-epic-installer"</code>

> <code>EPIC_DL_URL=_url_</code> # to download EPIC_FILENAME

> <code>CREATE_EIP_GATEWAY=True|False</code> # to enable/disable direct local network access for gateway # work in progress

### OPTIONAL # If you want customization
> <code>DOMAIN="ecp.demo"</code>

<pre># Define hosts in a rather strange way</pre>
> <code>hosts=('controller' 'gw' 'host1' 'host2' 'host3')</code> # hostnames are hard coded (avoid using name gateway as it is resolving to KVM host within VMs)
> <code>cpus=(16 4 8 8 8)</code>

> <code>mems=(65536 32768 65536 65536 65536)</code>

<pre># assign roles (for proper configuration script)</pre>
<pre># possible roles: controller gateway worker ad rdp mapr1 mapr2</pre>
> <code>roles=('controller' 'gateway' 'worker' 'worker' 'worker')</code>

<pre># disk sizes (data disk size per host)</pre>
> <code>disks=(512 0 512 512 512)</code>

### Installation

Run
```shell
./bin/kvm_create_new.sh
```

Wait for completion (45 min to 1.5h)

ssh scripts/commands will be copied to <code>./generated</code> directory. And connectivity information will be displayed as part of script output.

```shell
./generated/ssh_controller.sh
./generated/ssh_gw.sh
```

Open a browser to gateway (if CREATE_EIP_GATEWAY enabled an ip forwarding rule to ports 80/443/8080 will be created for local KVM host)
> https://gw.ecp.demo


# TODO

- [x] Test with non-root user

- [ ] Selectively deploy K8s cluster or EPIC cluster

- [ ] Attach to GPU on host

- [x] Public IP via host interface

- [ ] Enable RDP host

- [ ] Enable external MapR cluster

- [ ] Clean up (unneeded variables etc)

- [ ] Optimizations (less reboots, less modifications to source scripts etc)

- [ ] Enable mounted image catalog (nfs to avoid copying catalog images)

# Troubleshooting 

If you get error for backing disk not accessible "Permission denied", be sure that SE allows permission to all the way up to the backing file _/full/path/to/centos.qcow2_

Replace the full path: <code>sudo setfacl -m u:qemu:rx /full/path/to/</code>
If file is on NFS share: <code>sudo setsebool virt_use_nfs on</code>

