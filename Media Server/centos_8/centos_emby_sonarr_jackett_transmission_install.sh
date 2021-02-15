#!/bin/bash

## Getting environment ready
yum update -y
yum remove -y firewalld
setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
yum -y install epel-release

## Install Emby
yum install -y https://github.com/MediaBrowser/Emby.Releases/releases/download/4.3.0.30/emby-server-rpm_4.3.0.30_x86_64.rpm
systemctl enable emby-server
systemctl start emby-server
rm -rf emby-server-rpm_4.3.0.30_x86_64.rpm

## Sonarr Install
yum -y install snapd
systemctl enable --now snapd.socket
ln -s /var/lib/snapd/snap /snap
snap install sonarr
snap install sonarr   # Sometimes it fails the first time round.


## Install qBittorrent
yum -y install qbittorrent-nox
bash /usr/bin/qbittorrent-nox --daemon

## Install Jackett
yum -y install libicu
useradd jackett -s /sbin/nologin
wget https://github.com/Jackett/Jackett/releases/download/v0.17.538/Jackett.Binaries.LinuxAMDx64.tar.gz
tar xzvf Jackett.Binaries.LinuxAMDx64.tar.gz -C /opt
chown -R jackett:jackett /opt/Jackett
cd /opt/Jackett/ && ./install_service_systemd.sh

echo
echo "############################################################################"
echo "##   Emby should nou be available at http://<servername>:8096             ##"
echo "##   Sonarr should now be available on http://<servername>:8989           ##"
echo "##   qBittorrent should now be accessible from http://<servername>:8080   ##"
echo "##   Jackett can now be accessed at http://<servername>:9117              ##"
echo "############################################################################"
echo
echo "Remember these services will still need to be setup from their respective frontends/urls"
echo
echo "I recommend at the very least you add a blocklist to qBittorrent: http://john.bitsurge.net/public/biglist.p2p.gz"
echo
read -p "Press enter to continue"
echo

