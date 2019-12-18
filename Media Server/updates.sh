#!/bin/bash

#######################################################
##                                                   ##
##   Move the scripts/Media Server/ to ~/update      ##
##   Then use this script to run all the             ##
##   updates sequentially from a cron                ##
##                                                   ##
#######################################################

## Add this to the crontab:
## @reboot cd /root/update && updates.sh >> updates.log
## 0 3 * * * cd /root/update && updates.sh >> updates.log

echo "Update check starting at: "
date
echo "Current work directory is: "
pwd
echo
./centos_emby_update.sh
sleep 10
./centos_jackett_update.sh
sleep 10
./centos_plex_update.sh
sleep 10

echo
echo "Done, thanks for playing"
