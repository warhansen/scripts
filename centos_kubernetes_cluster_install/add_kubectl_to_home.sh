#!/bin/bash

user=$1

if [ -z "$1" ]
then
   echo ""
   echo "**  Please enter a username.surname when running the script  **"
   echo ""
   exit 1   
else
   sudo mkdir -p /home/$user/.kube
   sudo cp -i /etc/kubernetes/admin.conf /home/$user/.kube/config
   sudo echo 'KUBECONFIG=~/.kube/config' >> /home/$user/.profile
   sudo chown -R $user:$user /home/$user/
   cat /home/$user/.profile
   echo ""
   echo "-----------------------------------------"
   echo "The script was run successfully, please confirm the home profile printed above is correct"
   echo "-----------------------------------------"
   echo ""
fi
