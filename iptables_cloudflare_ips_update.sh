#!/bin/bash

file=/tmp/cloudflare_ips.txt
interface=enp0s3
port=443

curl -k -o $file https://www.cloudflare.com/ips-v4

while read line; do
   iptables -D INPUT -i $interface -s $line --dport $port -j ACCEPT
   iptables -A INPUT -i $interface -s $line --dport $port -j ACCEPT
done <$file

iptables-save > /etc/sysconfig/iptables
