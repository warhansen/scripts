#!/bin/bash

thisdir=$(pwd)

if [ $thisdir != "/root" ]; then
    echo "Please run this script from the 'root' folder!"
    exit 1
fi

## Getting environment ready
yum update -y
yum install -y wget tar
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
wget https://download.sonarr.tv/v3/main/3.0.6.1342/Sonarr.main.3.0.6.1342.linux.tar.gz
tar -xzvf Sonarr.main.3.0.6.1342.linux.tar.gz -C /opt/
rm -f Sonarr.main.3.0.6.1342.linux.tar.gz
chown -R sonarr:sonarr /opt/sonarr

tee /etc/systemd/system/sonarr.service << EOF
[Unit]
Description=Sonarr Daemon
After=syslog.target network.target
[Service]
User=sonarr
Group=sonarr
Type=simple
ExecStart=/usr/bin/mono /opt/Sonarr/Sonarr.exe -nobrowser -data /opt/Sonarr
TimeoutStopSec=20
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable sonarr.service
systemctl start sonarr.service


## Radarr Install - Same as Sonarr except for name changes
useradd radarr -s /sbin/nologin
cd /opt/
wget https://github.com/Radarr/Radarr/releases/download/v3.0.2.4552/Radarr.master.3.0.2.4552.linux.tar.gz
tar xzvf Radarr.master.3.0.2.4552.linux.tar.gz
rm -rf /opt/Radarr.master.3.0.2.4552.linux.tar.gz

tee /etc/systemd/system/radarr.service << EOF
[Unit]
Description=Radarr Daemon
After=syslog.target network.target

[Service]
User=radarr
Group=radarr
Type=simple
ExecStart=/usr/bin/mono /opt/Radarr/Radarr.exe -nobrowser -data /opt/Radarr
TimeoutStopSec=20

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable radarr.service
systemctl start radarr.service


## Install qBittorrent
yum install qbittorrent-nox
bash /usr/bin/qbittorrent-nox --daemon

## Install Jackett
yum -y install libicu
useradd jackett -s /sbin/nologin
wget https://github.com/Jackett/Jackett/releases/download/v0.12.1623/Jackett.Binaries.LinuxAMDx64.tar.gz
tar xzvf Jackett.Binaries.LinuxAMDx64.tar.gz -C /opt
chown -R sonarr:jackett /opt/Jackett
cd /opt/Jackett/ && ./install_service_systemd.sh

echo
echo "############################################################################"
echo "##   Emby should nou be available at http://<servername>:8096             ##"
echo "##   Sonarr should now be available on http://<servername>:8989           ##"
echo "##   Radarr should now be available on http://<servername>:7878           ##"
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

