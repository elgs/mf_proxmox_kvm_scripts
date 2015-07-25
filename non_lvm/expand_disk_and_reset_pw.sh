#!/bin/bash

# This script serves the purpose to work with Modules Factory Proxmox module 
# for WHMCS to do two things:
# 1. to expand the file system, disk partition and the disk image file;
# 2. to reset the root password;
# Please note this is the non-LVM version of the disk expansion script. 

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

# expand disk
cd "/var/lib/vz/images/${vmid}"

qemu-nbd -c /dev/nbd0 vm-${vmid}*
echo -e "d\nn\np\n\n\n\nw\n" | fdisk /dev/nbd0
e2fsck -fy /dev/nbd0p1
resize2fs /dev/nbd0p1

qemu-nbd -d /dev/nbd0

# reset root password
cd "/var/lib/vz/images/${vmid}"
mkdir -p a
qemu-nbd -c /dev/nbd0 vm-${vmid}*
mount /dev/nbd0p1 a
cd a

export password
perl -pe 's|(?<=root:)[^:]*|crypt($ENV{password},"\$6\$$ENV{password}\$")|e' etc/shadow > root/shadow
unset password
cp root/shadow etc/
rm root/shadow
cd ..

umount /dev/nbd0p1
qemu-nbd -d /dev/nbd0
rm -r a