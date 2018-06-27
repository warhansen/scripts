#!/bin/bash

export kubever=$(kubectl version | base64 | tr -d '\n') && kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$kubever"

echo "Going for a reboot"
sleep 3
reboot
