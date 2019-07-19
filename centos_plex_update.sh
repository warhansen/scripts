#!/bin/bash

## Install requirements
rpm -q jq
if [ $? -ne 0 ]; then
    yum -y install jq
else
    echo "jq installed"
fi

## ensure no failures if there are no old versions
plex_download_url=https://plex.tv/api/downloads/5.json
plex_download_file=/root/.5.json
old_plex_download_file=/root/.old_5.json

if [ -e $old_plex_download_file ]; then
    echo "there is an old version"
else
    touch $old_plex_download_file
fi

## Cleaning up the json file
wget $plex_download_url -O $plex_download_file
download_url=$(jq .computer $plex_download_file | grep "redhat/plexmediaserver" | grep "x86_64" | sed 's/"url": "//g' | sed 's/",//g' | tr -d [:space:])

diff  $plex_download_file  $old_plex_download_file

## Upgrading if necessary
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

## Recording old version
mv $plex_download_file $old_plex_download_file
