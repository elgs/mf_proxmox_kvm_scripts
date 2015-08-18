#!/bin/bash

# This script serves the purpose to work with Modules Factory Proxmox module 
# for WHMCS to do the following things:
# 1. to expand the file system, disk partition and the disk image file;
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

mp=$((vmid%10))
cd "/var/lib/vz/images/${vmid}"

qemu-nbd -c /dev/nbd${mp} vm-${vmid}*
echo -e "d\nn\np\n\n\n\nw\n" | fdisk /dev/nbd${mp}
e2fsck -fy /dev/nbd${mp}p1
resize2fs /dev/nbd${mp}p1

cd ..
umount /dev/nbd${mp}p1
qemu-nbd -d /dev/nbd${mp}
rm -r a