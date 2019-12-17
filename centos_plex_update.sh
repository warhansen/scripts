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
plex_download_file=5.json
version_check_file=plex_version_check
previous_version_check_file=plex_previous_version_check

## Extract version from the json file
wget $plex_download_url -O $plex_download_file
download_url=$(jq .computer $plex_download_file | grep "redhat/plexmediaserver" | grep "x86_64" | sed 's/"url": "//g' | sed 's/",//g' | tr -d [:space:])
echo $download_url > $version_check_file

## If this is the first time this script is run, do nothing, else match versions, if newer version is out, do upgrade
if [ -f $previous_version_check_file ]; then
    echo "There is a recorded previous version"
    if diff  $version_check_file $previous_version_check_file; then
        echo "No updates available"
    else
        wget $download_url -O plex_update.rpm
        systemctl stop plexmediaserver
        yum -y install plex_update.rpm
        sleep 10
        systemctl start plexmediaserver    
    fi
else
    echo "No previous version has been recorded."
fi

## Record current version for future use and cleanup old repos
mv $version_check_file $previous_version_check_file
rm -rf $plex_download_file $version_check_file plex_update.rpm
echo
