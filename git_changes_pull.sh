#!/bin/bash

folder = /etc/icinga/ng02

echo `date`
echo
echo "git Status:"
changed=0
cd $folder && git remote update && git status -uno | grep -q 'Your branch is behind' && changed=1
if [ $changed = 1 ]; then
   echo "There are changes to the GIT REPO"
   cd $folder && git pull
   echo
   echo "git has been pulled - if not working run from $folder:"
   echo "git config credential.helper store"
   echo "git pull"
   echo
else
   echo
   echo "There are no changes to the GIT REPO"
   echo "----------------------------------"
   echo
fi

