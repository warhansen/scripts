#!/bin/bash

echo
echo "**************************************************"
date
echo "Updating Emby"
date
echo

## Download git page to check version later
curl -o emby_check_update https://github.com/MediaBrowser/Emby.Releases/releases/

## Extract version from above page
version=$(curl -L https://github.com/MediaBrowser/Emby.Releases/releases/latest | grep 'href="/MediaBrowser/Emby.Releases/releases/tag' | egrep -o '[0-9].*' | egrep -o '^[^"]*"' | sed 's/"//g')
echo "Current released version is: " $version
echo $version > emby_released_version

## If this is the first time this script is run, do nothing, else match versions, if newer version is out, do upgrade
if [ -f previous_emby_released_version ]; then
    if diff emby_released_version previous_emby_released_version; then
        echo "There are no updates"
    else
        echo "There are new updates, please wait while they are installed"
        if curl https://github.com/MediaBrowser/Emby.Releases/releases/ | grep "${version}-beta"; then
            echo
            echo "Version ${version} is showing as ${version}-beta, so not downloading"
            echo
        else
            wget https://github.com/MediaBrowser/Emby.Releases/releases/download/${version}/emby-server-rpm_${version}_x86_64.rpm
            systemctl stop emby-server
            yum -y install emby-server-rpm_${version}_x86_64.rpm
            systemctl start emby-server
            sleep 10
            systemctl restart emby-server
            echo "Emby server has been updated"
        fi
    fi
else
    echo "No previous version has been recorded."
fi

## Record current version for future use and cleanup old repos
mv emby_released_version previous_emby_released_version
rm -rf emby-server-rpm_${version}_x86_64.rpm new_emby_version emby_check_update
