#!/bin/bash

echo
echo "**************************************************"
date
echo "Updating Jackett"
date
echo

## Download git page to check version later
curl -o jackett_check_update https://github.com/Jackett/Jackett/releases

## Extract version from above page
grep "/Jackett/Jackett/tree" jackett_check_update > new_jackett_version
version=$(cat new_jackett_version | sed 1q  | egrep -o '[0-9].*' | egrep -o '^[^"]*"' | sed 's/"//g')
jackett_version=$(echo "v"$version)
echo  $jackett_version > jackett_released_version
echo "Current released version is: " $jackett_version

## If this is the first time this script is run, do nothing, else match versions, if newer version is out, do upgrade
if [ -f previous_jackett_released_version ];then
    if diff jackett_released_version previous_jackett_released_version; then
        echo "There are no updates"
    else
        echo "There are new updates, please wait while they are installed"
	wget https://github.com/Jackett/Jackett/releases/download/$jackett_version/Jackett.Binaries.LinuxAMDx64.tar.gz
	systemctl stop jackett
	tar xzvf Jackett.Binaries.LinuxAMDx64.tar.gz -C /opt
	chown -R sonarr:plex /opt/Jackett
	sleep 10
	systemctl start jackett
	echo "jackett server has been updated"
    fi
else
    echo "No previous version has been recorded."
fi

## Record current version for future use and cleanup old repos
mv jackett_released_version previous_jackett_released_version
rm -rf Jackett.Binaries.LinuxAMDx64.tar.gz jackett_released_version new_jackett_version