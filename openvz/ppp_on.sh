#!/bin/bash

IN=$@

IFS=',' read varvmid varhostname varusername varpassword varmac varip varnode <<< "$IN";IFS='=' read var1 vmid <<< "$varvmid";IFS='=' read var2 hostname <<< "$varhostname";IFS='=' read var3 password <<< "$varpassword";IFS='=' read var4 username <<< "$varusername";IFS='=' read var5 macs <<< "$varmac";IFS='=' read var6 ips <<< "$varip";IFS='=' read var7 node <<< "$varnode"

vzctl set ${vmid} --features ppp:on --save
vzctl set ${vmid} --devnodes net/tun:rw --capability net_admin:on --save
vzctl start ${vmid}
vzctl set ${vmid} --devices c:108:0:rw --save
vzctl exec ${vmid} mknod /dev/ppp c 108 0
vzctl exec ${vmid} chmod 600 /dev/ppp
vzctl stop ${vmid}

