#!/bin/bash

yum -y update
/usr/bin/kubeadm init >> /root/.kubeinit.token
echo "KUBECONFIG=/etc/kubernetes/admin.conf" >> /etc/environment

echo "Going for a reboot"
sleep 3
reboot
