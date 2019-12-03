#!/bin/bash

## Getting environment ready
yum remove -y firewalld
setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

## Install Emby
yum install -y https://github.com/MediaBrowser/Emby.Releases/releases/download/4.3.0.30/emby-server-rpm_4.3.0.30_x86_64.rpm
systemctl enable emby-server
systemctl start emby-server
rm -rf emby-server-rpm_4.3.0.30_x86_64.rpm

## Sonarr Install - https://github.com/Sonarr/Sonarr/wiki/Installation-CentOS-7
yum install -y epel-release yum-utils wget git par2cmdline p7zip unrar unzip tar gcc python-feedparser python-configobj python-cheetah python-dbus python-devel libxslt-devel yum-utils
rpm --import "http://keyserver.ubuntu.com/pks/lookup?op=get&search=0x3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF"
yum-config-manager --add-repo http://download.mono-project.com/repo/centos/
yum install -y wget mediainfo libzen libmediainfo curl gettext mono-core mono-devel sqlite.x86_64
useradd sonarr -s /sbin/nologin
wget http://update.sonarr.tv/v2/master/mono/NzbDrone.master.tar.gz
tar -xvf ~/NzbDrone.master.tar.gz -C /opt/
rm -f NzbDrone.master.tar.gz
mkdir /opt/sonarr
mkdir /opt/sonarr/bin
mv /opt/NzbDrone/* /opt/sonarr/bin
rm -rf /opt/NzbDrone
chown -R sonarr:sonarr /opt/sonarr

tee /etc/systemd/system/sonarr.service << EOF
[Unit]
Description=Sonarr Daemon
After=syslog.target network.target
[Service]
User=sonarr
Group=sonarr
Type=simple
ExecStart=/usr/bin/mono /opt/sonarr/bin/NzbDrone.exe -nobrowser -data /opt/sonarr
TimeoutStopSec=20
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable sonarr.service
systemctl start sonarr.service

## Install transmission
yum -y install transmission-cli transmission-common transmission-daemon
systemctl enable transmission-daemon
systemctl start transmission-daemon
systemctl stop transmission-daemon
sed -i 's/"rpc-whitelist": "127.0.0.1"/"rpc-whitelist": "*.*.*.*"/g' /var/lib/transmission/.config/transmission-daemon/settings.json
systemctl start transmission-daemon

## Install Jackett
sudo yum -y install libicu
useradd jackett -s /sbin/nologin
wget https://github.com/Jackett/Jackett/releases/download/v0.12.926/Jackett.Binaries.LinuxAMDx64.tar.gz
tar xzvf Jackett.Binaries.LinuxAMDx64.tar.gz -C /opt
chown -R sonarr:jackett /opt/Jackett
cd /opt/Jackett/ && ./install_service_systemd.sh

echo
echo "############################################################################"
echo "##   Emby should nou be available at http://<servername>:8096             ##"
echo "##   Sonarr should now be available on http://<servername>:8989           ##"
echo "##   Transmission should now be accessible from http://<servername>:9091  ##"
echo "##   Jackett can now be accessed at http://<servername>:9117              ##"
echo "############################################################################"
echo
echo "Remember these services will still need to be setup from their respective frontends/urls"
echo
echo "I recommend at the very least you add a blocklist to transmission: http://john.bitsurge.net/public/biglist.p2p.gz"
echo
read -p "Press enter to continue"
echo

