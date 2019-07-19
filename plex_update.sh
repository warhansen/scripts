#!/bin/bash

rpm -q jq
if [ $? -ne 0 ]; then
    yum -y install jq
else
    echo "jq installed"
fi


plex_download_url=https://plex.tv/api/downloads/5.json
plex_download_file=/root/.5.json
old_plex_download_file=/root/.old_5.json

wget $plex_download_url -O $plex_download_file
download_url=$(jq .computer $plex_download_file | grep "redhat/plexmediaserver" | grep "x86_64" | sed 's/"url": "//g' | sed 's/",//g' | tr -d [:space:])

diff  $plex_download_file  $old_plex_download_file

if [ $? -ne 0 ]; then
    wget $download_url -O /root/plex_update.rpm
    yum -y install /root/plex_update.rpm
    rm -rf /root/plex_update
    rm -rf /root/update_file.plex
    systemctl stop plexmediaserver
    sleep 15
    systemctl start plexmediaserver
else
    echo "No updates available"
fi

mv $plex_download_file $old_plex_download_file
