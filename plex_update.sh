#!/bin/bash

file=/root/update_file.plex
download_url=$(cat $file)

if [ -e $file ]; then
    wget $download_url -O /root/plex_update.rpm
    yum -y install /root/plex_update.rpm
    rm -rf /root/plex_update
    rm -rf /root/update_file.plex
    systemctl stop plexmediaserver
    sleep 15
    systemctl start plexmediaserver
fi
