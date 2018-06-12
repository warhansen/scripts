#!/bin/bash

# Only change this:
current_ifname=enp0s3

# Leave the rest alone
new_ifname=eth0

sed -i 's+quiet"+quiet net.ifnames=0 biosdevname=0"+g' /etc/default/grub

grub2-mkconfig -o /boot/grub2/grub.cfg

mv /etc/sysconfig/network-scripts/ifcfg-$current_ifname /etc/sysconfig/network-scripts/ifcfg-$new_ifname

sed -i "s+$current_ifname+$new_ifname+g" /etc/sysconfig/network-scripts/ifcfg-$new_ifname

echo "Server is now going to reboot"
sleep 3

reboot
