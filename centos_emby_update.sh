curl -o emby_check_update https://github.com/MediaBrowser/Emby.Releases/releases/

grep "/MediaBrowser/Emby.Releases/tree" emby_check_update > new_emby_version
version=$(cat new_emby_version | sed 1q  | egrep -o '[0-9].*' | egrep -o '^[^"]*"' | sed 's/"//g')
echo "Current released version is: " $version
echo $version > emby_released_version

if [ -f previous_emby_released_version ];then
    if diff emby_released_version previous_emby_released_version; then
        echo "There are no updates"
    else
        echo "There are new updates, please wait while they are installed"
        systemctl stop emby-server
        yum install https://github.com/MediaBrowser/Emby.Releases/releases/download/${version}/emby-server-rpm_${version}_x86_64.rpm
	sleep 10
	systemctl start emby-server
	echo "Emby server has been updated"
    fi
fi

mv emby_released_version previous_emby_released_version