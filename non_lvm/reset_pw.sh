#!/bin/bash

# This script serves the purpose to work with Modules Factory Proxmox module 
# for WHMCS to reset root password for KVM template virtual machines. This 
# script can 1) set root password on provision before the first boot of the 
# virtual machine, 2) reset password when user changes root password in the
# client area using Modules Factory Proxmox module.

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

export password
perl -pe 's|(?<=root:)[^:]*|crypt($ENV{password},"\$6\$$ENV{password}\$")|e' etc/shadow > root/shadow
unset password
cp root/shadow etc/
rm root/shadow

cd ..
umount /dev/nbd${mp}p1
qemu-nbd -d /dev/nbd${mp}
rm -r a