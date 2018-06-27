#!/bin/bash

yum -y update
/usr/bin/kubeadm init >> /root/kubeinit.token
echo "KUBECONFIG=/etc/kubernetes/admin.conf" >> /etc/environment

echo ""
echo -e "\033[0;92m After reboot, please check the last paragraph of /root/kubeinit.token file \033[0m"
echo -e "\033[0;92m for the kubeadm command to run from the worker nodes, in order to join them \033[0m"
echo -e "\033[0;92m to the cluster \033[0m"
echo ""

sleep 3

echo "Going for a reboot"
sleep 3
reboot
