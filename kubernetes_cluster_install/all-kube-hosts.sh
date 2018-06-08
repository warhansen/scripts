#!/bin/bash

yum -y update

sed -i 's+SELINUX=enforcing+SELINUX=disabled+g' /etc/selinux/config
setenforce 0

sed -i 's+/dev/mapper/os-swap+##/dev/mapper/os-swap+g' /etc/fstab

swapoff -a

systemctl disable firewalld

cat >  /etc/sysctl.d/k8s.conf << EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

sysctl -p

yum install -y docker
systemctl enable docker && systemctl start docker

cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

yum install -y kubelet kubeadm kubectl
systemctl enable kubelet && systemctl start kubelet

echo
echo
echo "This script has completed successfully!"

echo "Going for a reboot"
sleep 3
reboot

