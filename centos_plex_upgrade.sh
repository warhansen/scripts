#!/bin/bash

echo
echo "*******************************"
date
echo

## Install requirements
rpm -q jq
if [ $? -ne 0 ]; then
    yum -y install jq
else
    echo "jq installed"
fi

rpm -q wget
if [ $? -ne 0 ]; then
    yum -y install wget
else
    echo "wget installed"
fi

## Setting Variables
plex_download_url=https://plex.tv/api/downloads/5.json
plex_download_file=/root/.5.json
version_check_file=/root/.version_check.txt
old_version_check_file=/root/.old_version_check.txt

## Cleaning up the json file
wget $plex_download_url -O $plex_download_file
download_url=$(jq .computer $plex_download_file | grep "redhat/plexmediaserver" | grep "x86_64" | sed 's/"url": "//g' | sed 's/",//g' | tr -d [:space:])

## ensure no failures if there are no old versions
if [ -e $old_version_check_file ]; then
    echo "there is a recorded old version"
else
    touch $old_version_check_file
fi

echo $download_url > $version_check_file

diff  $version_check_file $old_version_check_file

## Upgrading if necessary
if [ $? -ne 0 ]; then
    wget $download_url -O /root/plex_update.rpm
    yum -y install /root/plex_update.rpm
    rm -rf /root/plex_update.rpm
    systemctl stop plexmediaserver
    sleep 15
    systemctl start plexmediaserver
else
    echo "No updates available"
fi

## Recording old version
mv $version_check_file $old_version_check_file

## Cleaning up
rm -rf $plex_download_file
echo
