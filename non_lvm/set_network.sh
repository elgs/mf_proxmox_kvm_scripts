#!/bin/bash

# This script serves the purpose to work with Modules Factory Proxmox module 
# for WHMCS to do the following things:
# 1. to set network, currently only for Debian & Redhat derivatives;

# Please note the following things before using this script:
# 1. This script assumes the KVM template image files are located at 
#    /var/lib/vz/images/xxx, where xxx is the numeric vmid;
# 2. This script assumes qemu-nbd is installed on the Proxmox host;
# 3. The password is immediately set on provision before the first boot of
#    virtual machine;
# 4. The virtual machine needs a reboot after changing password from the 
#    client area.

IN=$@

IFS=',' read varvmid varhostname varusername varpassword varmac varip varnode <<< "$IN";IFS='=' read var1 vmid <<< "$varvmid";IFS='=' read var2 hostname <<< "$varhostname";IFS='=' read var3 password <<< "$varpassword";IFS='=' read var4 username <<< "$varusername";IFS='=' read var5 macs <<< "$varmac";IFS='=' read var6 ips <<< "$varip";IFS='=' read var7 node <<< "$varnode"

mp=$((vmid%10))
cd "/var/lib/vz/images/${vmid}"
mkdir -p a
qemu-nbd -c /dev/nbd${mp} vm-${vmid}*
mount /dev/nbd${mp}p1 a
cd a

ip=${ips}
mac=${macs}
gw=192.99.21.254
ns1=213.186.33.99
ns2=8.8.8.8
ns3=8.8.4.4

# Debian & derivatives (Ubuntu, CrunchBang, SteamOS...)
if [ -f usr/bin/apt-get ]; then
cat > etc/network/interfaces << EOF
auto lo eth0
iface lo inet loopback
iface eth0 inet static
    address $ip
    netmask 255.255.255.255
    broadcast $ip
    post-up route add $gw dev eth0
    post-up route add default gw $gw
    pre-down route del $gw dev eth0
    pre-down route del default gw $gw
EOF

# DNS
cat > etc/resolv.conf << EOF
nameserver $ns1
nameserver $ns2
nameserver $ns3
EOF
fi

# Set network
# Redhat & derivatives (CentOS, Scientific Linux, ClearOS...)
if [ -f usr/bin/yum ]; then
cat > etc/sysconfig/network-scripts/ifcfg-eth0 << EOF
DEVICE=eth0
BOOTPROTO=none
ONBOOT=yes
USERCTL=no
IPV6INIT=no
PEERDNS=yes
TYPE=Ethernet
NETMASK=255.255.255.255
IPADDR=$ip
GATEWAY=$gw
ARP=yes
HWADDR=$mac
EOF

cat > etc/sysconfig/network-scripts/route-eth0 << EOF
$gw dev eth0
default via $gw dev eth0
EOF

# DNS
cat > etc/resolv.conf << EOF
nameserver $ns1
nameserver $ns2
nameserver $ns3
EOF
fi

cd ..
umount /dev/nbd${mp}p1
qemu-nbd -d /dev/nbd${mp}
rm -r a
