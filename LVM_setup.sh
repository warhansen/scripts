#!/usr/bin/env bash

## Checking if being run as root

clear
if [[ $(id -u) -ne 0 ]]
then
   echo -e "\033[0;92m Please run this script as root \033[0m"
   echo ""
   exit 1
fi

## Main Functions

yum_dialog() {
if yum list installed "dialog" >/dev/null 2>&1; then
   echo -e "\033[0;92m The Dialog package is installed \033[0m"
else
   yum install -y dialog
   echo -e "\033[0;92m Installing the dialog package \033[0m"
fi
}

apt_dialog() {
if dpkg -l "dialog" >/dev/null 2>&1; then
   echo -e "\033[0;92m The Dialog package is installed \033[0m"
else
   apt-get install dialog
   echo -e "\033[0;92m Installing the dialog package \033[0m"
fi
}

check_os() {
if [ -f /etc/redhat-release ]; then
   yum_dialog
elif [ -f /etc/lsb-release ]; then
   apt_dialog
fi
}


## Dialog LVM

dialog_menu() {

## Dialog Functions

exit_check() {
response=$?
if [ $response == 1 ]; then
	dialog --title "Exit" --infobox "You chose to cancel, please run the script again, it is going to exit" 0 0 ; sleep 3
	exit 1
	clear
fi
}

## dialog_menu Main Menu

choice=$(dialog --menu "LVM Setup" 0 0 0 1 "Create a new LVM" 2 "Add to and existing LVM" 3 "Quit" --output-fd 1)

clear
case $choice in

## dialog_menu Menu Option 1

        1)
		df -h > current_space1
		fdisk -l | grep /dev/sd > fdisk_output1
		for BUS in /sys/class/scsi_host/host*/scan; do
		echo "- - -" >  ${BUS}
		done
		ls /sys/class/scsi_disk/ > devices
		while read line; do
			cd /sys/class/scsi_device && cd $line && echo 1> device/rescan && cd
		done <devices
		rm -rf devices
		fdisk -l | grep /dev/sd > fdisk_output2
		if diff fdisk_output1 fdisk_output2 ; then
			drive=$(dialog --inputbox "No HDD space changes have been detected. Please enter the drive you want to use to add to the LVM. Use the full path, eg: /dev/sdb \n\n$(fdisk -l | grep /dev/sd)" 20 70 --output-fd 1)
			exit_check
		else
			disk_check=$(diff fdisk_output1 fdisk_output2 | wc -l)
			if [ $disk_check -gt 2 ]; then
				dialog --title "Choose drive"  --yesno "The drive to be used is: \n $(diff fdisk_output1 fdisk_output2 | grep /dev/sd | sed '1D' | cut -d' ' -f3 | tr -d ':'). Is this correct?"  0 0
				response=$?
				case $response in
					0) drive=$(diff fdisk_output1 fdisk_output2 | grep /dev/sd | sed '1D' | cut -d' ' -f3 | tr -d ':') ;;
					1) dialog --infobox "Please run the script again, it is going to exit" 0 0 ; sleep 3
						exit 1;;
					255) exit 1 ;;
				esac
				drive=$(diff fdisk_output1 fdisk_output2 | grep /dev/sd | sed '1D' | cut -d' ' -f3 | tr -d ':')
			else
				dialog  --title "Choose drive" --yesno "The drive to be used is: \n $(diff fdisk_output1 fdisk_output2 | grep /dev/sd | cut -d' ' -f3 | tr -d ':'). \n Is this correct?"  0 0
				response=$?
				case $response in
					0) drive=$(diff fdisk_output1 fdisk_output2 | grep /dev/sd | cut -d' ' -f3 | tr -d ':') ;;
					1) dialog --msgbox "Please run the script again, it is going to exit" 0 0
						exit 1 ;;
					255) exit 1 ;;
				esac
				drive=$(diff fdisk_output1 fdisk_output2 | grep /dev/sd | cut -d' ' -f3 | tr -d ':')
			fi
		fi

		drive_state=$(fdisk -l | grep -c $drive)
		if [ $drive_state -eq 1 ]; then
			echo ""
			echo -e "\033[0;92m This is a new drive, formatting now \033[0m"
			echo ""
			echo -e "n\n\n\n\n\n\nt\n8e\nw" | fdisk $drive
			echo ""
		elif [ $drive_state -ge 2 ]; then
			echo -e "\033[0;92m This drive already has partitions, formatting now \033[0m"
			echo -e "n\n\n\n\n\n\nt\n\n8e\nw" | fdisk $drive
			echo ""
		fi

		partprobe
		pvscan
		sleep 3
		fdisk -l | grep /dev/sd > fdisk_output3

		if diff fdisk_output2 fdisk_output3; then
			dialog --title "Exit" --msgbox "fdisk has ** not ** successfully partitioned the disk, script is now going to exit" 0 0
			exit 1
			clear
		else
			dialog --title "Choose partition"  --yesno "The new partition to be used to create the LVM will be: \n$(diff fdisk_output2 fdisk_output3 | sed '/:/d' | grep /dev/sd | cut -d' ' -f2). Is this correct?"  0 0
			response=$?
			case $response in
				0) partition=$(diff fdisk_output2 fdisk_output3 | sed '/:/d' | grep /dev/sd | cut -d' ' -f2) ;;
				1) dialog --title "Exit" --infobox "Plese run the script again, it is going to exit" 0 0 ; sleep 3
					exit 1
					clear ;;
				255) exit 1 ;;
			esac
		fi

		pvcreate $partition
		dialog --title "Creating" --infobox "Busy running the pvcreate command" 0 0 ; sleep 3

		vgname=$(dialog --inputbox "What would you like to call your Volume Group? (This will not be used as the mount point, so you can call it anything you like)" 0 0 --output-fd 1)
		exit_check
		while [[ $vgname == *['!'@#\$%^\&*()_+]* ]]; do
			vgname=$(dialog --inputbox "Your name contains special characters, please only use normal characters)" 0 0 --output-fd 1)
			exit_check
		done
		vgcreate $vgname $partition
		dialog --title "Creating" --infobox "Busy creating the Volume Group" 0 0 ; sleep 3

		lvname=$(dialog --inputbox "What would you like to call your Logical Volume? \n(This will not be used as the mount point, so you can call it anything you like. I suggest calling it the same as the folder where you are going to mount it" 0 0 --output-fd 1)
		exit_check
		while [[ $lvname == *['!'@#\$%^\&*()_+]* ]]; do
			lvname=$(dialog --inputbox "Your name contains special characters, please only use normal characters" 0 0 --output-fd 1)
			if [ $response == 1 ]; then
				dialog --title "Exit" --infobox "You chose to cancel, please run the script again, it is going to exit" 0 0 ; sleep 3
				exit 1
			fi
		done
		dialog --title "Creating" --infobox "Busy creating the Logical Volume" 0 0 ; sleep 3
		lvcreate -l 100%FREE -n $lvname $vgname

		file_system=$(dialog --inputbox "What file system would you like to use? ext4, ext3 or xfs" 0 0 --output-fd 1)
		exit_check
		while [[ ! "$file_system" =~ ^(ext4|ext3|xfs)$ ]]; do
			file_system=$(dialog --inputbox "What file system would you like to use? ext4, ext3 or xfs" 0 0 --output-fd 1)
			exit_check
		done
		mkfs.$file_system /dev/$vgname/$lvname
		mount_point=$(dialog --inputbox "Where would you like to mount your new LVM? Please type the full path, eg: /mnt/data" 0 0 --output-fd 1)
		exit_check
		mkdir $mount_point
		mount /dev/$vgname/$lvname $mount_point
		echo "/dev/$vgname/$lvname $mount_point $file_system defaults 0 0" >> /etc/fstab
		lvdisplay | grep /dev/$vgname/$lvname $mount_point

		dialog --infobox "Removing tmp files used in this script" 0 0 ; sleep 3
		rm -rf fdisk_output1 fdisk_output2 fdisk_output3 current_space1 current_space2 drive
		dialog --title "Success" --msgbox "$** Success! your new LVM has now been created and added to the fstab so it will be mounted when you reboot! **"  10 40
		dialog --msgbox "$(fdisk -l | grep /dev)" 20 0
		clear
		;;

## dialog_menu Menu Option 2

        2)
		df -h > current_space1
		fdisk -l | grep /dev/sd > fdisk_output1
		for BUS in /sys/class/scsi_host/host*/scan; do
		echo "- - -" >  ${BUS}
		done
		ls /sys/class/scsi_disk/ > devices
		while read line; do
			cd /sys/class/scsi_device && cd $line && echo 1> device/rescan && cd
		done <devices
		rm -rf devices
		fdisk -l | grep /dev/sd > fdisk_output2
		if diff fdisk_output1 fdisk_output2 ; then
			drive=$(dialog --inputbox "No HDD space changes have been detected. Please enter the drive you want to use to add to the LVM. Use the full path, eg: /dev/sdb \n\n$(fdisk -l | grep /dev/sd)" 20 70 --output-fd 1)
			exit_check
		else
			disk_check=$(diff fdisk_output1 fdisk_output2 | wc -l)
			if [ $disk_check -gt 2 ]; then
				dialog --title "Choose drive"  --yesno "The drive to be used is: \n $(diff fdisk_output1 fdisk_output2 | grep /dev/sd | sed '1D' | cut -d' ' -f3 | tr -d ':'). Is this correct?"  0 0
				response=$?
				case $response in
					0) drive=$(diff fdisk_output1 fdisk_output2 | grep /dev/sd | sed '1D' | cut -d' ' -f3 | tr -d ':') ;;
					1) dialog --infobox "Please run the script again, it is going to exit" 0 0 ; sleep 3
						exit 1;;
					255) exit 1 ;;
				esac
				drive=$(diff fdisk_output1 fdisk_output2 | grep /dev/sd | sed '1D' | cut -d' ' -f3 | tr -d ':')
			else
				dialog  --title "Choose drive" --yesno "The drive to be used is: \n $(diff fdisk_output1 fdisk_output2 | grep /dev/sd | cut -d' ' -f3 | tr -d ':'). \n Is this correct?"  0 0
				response=$?
				case $response in
					0) drive=$(diff fdisk_output1 fdisk_output2 | grep /dev/sd | cut -d' ' -f3 | tr -d ':') ;;
					1) dialog --msgbox "Please run the script again, it is going to exit" 0 0
						exit 1 ;;
					255) exit 1 ;;
				esac
				drive=$(diff fdisk_output1 fdisk_output2 | grep /dev/sd | cut -d' ' -f3 | tr -d ':')
			fi
		fi

		drive_state=$(fdisk -l | grep -c $drive)
		if [ $drive_state -eq 1 ]; then
			echo -e "\033[0;92m This is a new drive, formatting now \033[0m"
			echo -e "n\n\n\n\n\n\nt\n8e\nw" | fdisk $drive
		elif [ $drive_state -gt 1 ]; then
			echo -e "\033[0;92m This drive already has partitions, formatting now \033[0m"
			echo -e "n\n\n\n\n\n\nt\n\n8e\nw" | fdisk $drive
		fi

		partprobe
		pvscan
		fdisk -l | grep /dev/sd > fdisk_output3

		if diff fdisk_output2 fdisk_output3; then
			dialog --msgbox "fdisk has ** not ** successfully partitioned the disk, script is now going to exit" 0 0
			exit 1
			clear
		else
			dialog --yesno "The new partition to be used to create the LVM will be: \n$(diff fdisk_output2 fdisk_output3 | sed '/:/d' | grep /dev/sd | cut -d' ' -f2). \nIs this correct?"  0 0
			response=$?
			case $response in
				0) partition=$(diff fdisk_output2 fdisk_output3 | sed '/:/d' | grep /dev/sd | cut -d' ' -f2);;
				1) dialog --title "Exit" --infobox "Plese run the script again, it is going to exit" 0 0 ; sleep 3
					exit 1 ;;
				255) exit 1 ;;
			esac
		fi

		pvcreate $partition
		dialog --infobox "Busy running the pvcreate command" 0 0 ; sleep 3
		vgname=$(dialog --inputbox "These are current existing Volume Groups, which one would you like to use? (ONLY type the name) \n\n$(vgdisplay | grep 'VG Name')" 20 70 --output-fd 1)
		exit_check
		while [[ $vgname == *['!'@#\$%^\&*()_+]* ]]; do
			vgname=$(dialog --inputbox "These are current existing Volume Groups, which one would you like to use? (ONLY type the name) \n\n$(vgdisplay | grep 'VG Name')" 20 70 --output-fd 1)
			exit_check
		done
		vgextend $vgname $partition
		dialog --title "Resizing" --infobox "Busy extending the Volume Group" 0 0 ; sleep 3
		lvpath=$(dialog --inputbox "These are the current existing Logical Volumes, which one would you like to use? (ONLY type the path, but type the full path, eg: /dev/vg_name/lv_name) \n\n$(lvdisplay | grep 'LV Path' | grep $vgname)" 20 70 --output-fd 1)
		exit_check
		dialog --title  "Are you sure" --yesno "You wanted to use \n $lvpath \nIs this correct?\n" 0 0
		response=$?
		if [ $response == 1 ]; then
			lvpath=$(dialog --inputbox "These are the current existing Logical Volumes, which one would you like to use? (ONLY type the path, but type the full path, eg: /dev/vg_name/lv_name) \n\n$(lvdisplay | grep 'LV Path')" 20 70 --output-fd 1)
		fi
		dialog --title "Resizing" --infobox "Busy extending the Logical Volume" 0 0 ; sleep 3
		lvextend $lvpath $partition

		get_filesystem=$(grep $lvpath /etc/fstab | tr -s ' ' | cut -d' ' -f3)

		if [ "$get_filesystem" == "" ]; then
			file_system=$(dialog --inputbox "No filesystem was automatically detected, please inspect the /etc/fstab below and enter the filesystem you need: ext4, ext3, or xfs: \n\n$(cat /etc/fstab)" 20 80 --output-fd 1)
			exit_check
		else
			dialog --yesno "The current file system of the LVM is: \n $(grep $lvpath /etc/fstab | tr -s ' ' | cut -d' ' -f3). Is this correct"  0 0
			response=$?
			case $response in
				0) file_system=$(grep $lvpath /etc/fstab | tr -s ' ' | cut -d' ' -f3) ;;
				1) file_system=$(dialog --inputbox "Please enter a filesystem: ext3, ext4 or nfs" 20 70 --output-fd 1)
					exit_check ;;
				255) exit 1 ;;
			esac
		while [[ ! "$file_system" =~ ^(ext4|ext3|xfs)$ ]]; do
			file_system=$(dialog --inputbox "Please enter a valid filesystem: ext3, ext4 or nfs" 20 70 --output-fd 1)
			exit_check
		done
		fi

		if [[ "$file_system" =~ ^(ext4|ext3)$ ]]; then
			dialog --title "Resizing" --infobox "Resizing the Logical Volume now!" 0 0 ; sleep 3
			resize2fs $lvpath
		else
			dialog --title "Resizing" --infobox "Resizing the Logical Volume now!" 0 0 ; sleep 3
			xfs_growfs $lvpath
		fi

		df -h > current_space2
		if diff -y current_space1 current_space2; then
			dialog --title "Exit" --msgbox "The space was not added. Please double check the lvextend or resize command, exiting the script!" 0 0
			exit 1
		else
			dialog --title "Success!" --msgbox "** The new HDD space has been added to your exiting LVM! **" 0 0
			dialog --title "df -h" --msgbox "$(df -h)" 20 0
		fi
		rm -rf fdisk_output1 fdisk_output2 fdisk_output3 current_space1 current_space2 drive
		clear
		;;

## Option "Quit"

        3)
		dialog --msgbox "You have selected to exit the script!" 0 0
		clear
		;;
esac

}


## Bash LVM

bash_menu() {

## Main Menu

echo -e "\033[0;92m Do you want to:
1 -> Create a new LVM or
2 -> Adding to an existing LVM
Please enter the number of your choice \033[0m
"
read -p '> ' choice
echo ""

## bash_menu Choice 1 from main menu

if [ $choice == 1 ]
then
   df -h > current_space1
   fdisk -l | grep /dev/sd > fdisk_output1
   for BUS in /sys/class/scsi_host/host*/scan; do
   echo "- - -" >  ${BUS}
   done
   ls /sys/class/scsi_disk/ > devices
   while read line; do cd /sys/class/scsi_device && cd $line && echo 1> device/rescan && cd
   done <devices
   rm -rf devices
   fdisk -l | grep /dev/sd > fdisk_output2
   if diff fdisk_output1 fdisk_output2
   then
      fdisk -l | grep /dev/sd
      echo ""
      echo -e "\033[0;92m No HDD space changes have been detected. Please enter the drive you want to use to
add to the LVM. Use the full path, eg: /dev/sdb \033[0m"
      echo ""
      read -p '> ' drive
   else
      echo ""
      echo -e "\033[0;92m The drive to be used to add to the current LVM will be: \033[0m"
      echo ""
      disk_check=$(diff fdisk_output1 fdisk_output2 | wc -l)
      if [ $disk_check -gt 2 ]
      then
         drive=$(diff fdisk_output1 fdisk_output2 | grep /dev/sd | sed '1D' | cut -d' ' -f3 | tr -d ':')
	 echo $drive
         echo ""
         echo -e "\033[0;92m If this is correct, press the ENTER key. If not press CTRL + C now and run the script again! \033[0m"
         echo ""
         read -p ""
      else
         drive=$(diff fdisk_output1 fdisk_output2 | grep /dev/sd | cut -d' ' -f3 | tr -d ':')
         echo $drive
         echo ""
         echo -e "\033[0;92m If this is correct, press the ENTER key. If not press CTRL + C now and run the script again! \033[0m"
         echo ""
         read -p ""
      fi
   fi

   drive_state=$(fdisk -l | grep -c $drive)
   if [ $drive_state -eq 1 ]
      then
         echo ""
	 echo -e "\033[0;92m This is a new drive, formatting now \033[0m"
         echo ""
	 echo -e "n\n\n\n\n\n\nt\n8e\nw" | fdisk $drive
         echo ""
   elif [ $drive_state -ge 2 ]
      then
         echo -e "\033[0;92m This drive already has partitions, formatting now \033[0m"
	 echo -e "n\n\n\n\n\n\nt\n\n8e\nw" | fdisk $drive
         echo ""
   fi

   partprobe
   pvscan
   fdisk -l | grep /dev/sd > fdisk_output3

   if diff fdisk_output2 fdisk_output3
   then
      "\033[0;92m fdisk has ** not ** successfully partitioned the disk, script is now going to exit \033[0m"
      exit 1
   else
      echo ""
      echo -e "\033[0;92m The new partition to be used to create the LVM will be: \033[0m"
      echo ""
      diff fdisk_output2 fdisk_output3 | sed '/:/d' | grep /dev/sd | cut -d' ' -f2
      echo ""
      echo -e "\033[0;92m If this is correct, press the ENTER key. If not press CTRL + C now! \033[0m"
      echo ""
      read -p ""
   fi
   partprobe
   pvscan
   partition=$(diff fdisk_output2 fdisk_output3 | sed '/:/d' | grep /dev/sd | cut -d' ' -f2)
   echo ""
   echo -e "\033[0;92m Running pvcreate command \033[0m"
   echo ""
   pvcreate $partition
   echo ""
   echo -e "\033[0;92m What would you like to call your Volume Group? (This will not be used
as the mount point, so you can call it anything you like \033[0m"
   echo ""
   read -p '> ' vgname
   while [[ $vgname == *['!'@#\$%^\&*()_+]* ]]
   do
      echo -e "\033[0;92m Your name contains special characters, please only use normal characters \033[0m"
      read -p '> ' vgname
   done
   echo ""
   vgcreate $vgname $partition
   echo ""
   echo -e "\033[0;92m What would you like to call your Logical Volume? (This will not be used
as the mount point, so you can call it anything you like. I suggest calling it the same
as the folder where you are going to mount it \033[0m"
   echo ""
   read -p '> ' lvname
   while [[ $lvname == *['!'@#\$%^\&*()_+]* ]]
   do
      echo -e "\033[0;92m Your name contains special characters, please only use normal characters \033[0m"
      read -p '> ' lvname
   done
   echo ""
   echo -e "\033[0;92m Creating the new LVM now! \033[0m"
   echo ""
   lvcreate -l 100%FREE -n $lvname $vgname
   echo ""
   echo -e "\033[0;92m What file system would you like to use? ext4, ext3 or xfs. \033[0m"
   echo ""
   read -p '> ' file_system
   echo ""

   while [[ ! "$file_system" =~ ^(ext4|ext3|xfs)$ ]]
   do
      echo -e "\033[0;92m What file system would you like to use? ext4, ext3 or xfs. \033[0m"
      echo ""
      read -p '> ' file_system
      echo ""
   done
   mkfs.$file_system /dev/$vgname/$lvname
   echo -e "\033[0;92m Where would you like to mount your new LVM? Please type the
full path, eg: /mnt/data \033[0m"
   echo ""
   read -p '> ' mount_point
   mkdir $mount_point
   mount /dev/$vgname/$lvname $mount_point
   echo "/dev/$vgname/$lvname $mount_point $file_system defaults 0 0" >> /etc/fstab
   lvdisplay | grep /dev/$vgname/$lvname $mount_point
   echo ""
   echo -e "\033[0;92m Removing tmp files used in this script \033[0m"
   rm -rf fdisk_output1 fdisk_output2
   fdisk -l | grep /dev
   echo ""
   df -h
   echo ""
   echo -e "\033[0;92m -------------------------------------------------------"
   echo -e "\033[0;92m ** Success! your new LVM has now been created and added to the fstab so it will be
mounted when you reboot! **"
   echo -e "\033[0;92m -------------------------------------------------------\033[0m "
   echo ""
   df -h
   echo ""
   rm -rf current_space1 current_space2
   rm -rf fdisk_output1 fdisk_output2 fdisk_output3

## Bash_menu Choice 2 from main menu

elif [ $choice == 2 ]
then
   df -h > current_space1
   fdisk -l | grep /dev/sd > fdisk_output1
   for BUS in /sys/class/scsi_host/host*/scan; do
   echo "- - -" >  ${BUS}
   done
   ls /sys/class/scsi_disk/ > devices
   while read line; do cd /sys/class/scsi_device && cd $line && echo 1> device/rescan && cd
   done <devices
   rm -rf devices
   fdisk -l | grep /dev/sd > fdisk_output2
   if diff fdisk_output1 fdisk_output2
   then
      fdisk -l | grep /dev/sd
      echo ""
      echo -e "\033[0;92m No HDD space changes have been detected. Please enter the drive you want to use to
add to the LVM. Use the full path, eg: /dev/sdb \033[0m"
      echo ""
      read -p '> ' drive
   else
      echo ""
      echo -e "\033[0;92m The drive to be used to add to the current LVM will be: \033[0m"
      echo ""
      disk_check=$(diff fdisk_output1 fdisk_output2 | wc -l)
      if [ $disk_check -gt 2 ]
      then
         drive=$(diff fdisk_output1 fdisk_output2 | grep /dev/sd | sed '1D' | cut -d' ' -f3 | tr -d ':')
	 echo $drive
         echo ""
         echo -e "\033[0;92m If this is correct, press the ENTER key. If not press CTRL + C now and run the script again! \033[0m"
         echo ""
         read -p ""
      else
         drive=$(diff fdisk_output1 fdisk_output2 | grep /dev/sd | cut -d' ' -f3 | tr -d ':')
         echo $drive
         echo ""
         echo -e "\033[0;92m If this is correct, press the ENTER key. If not press CTRL + C now and run the script again! \033[0m"
         echo ""
         read -p ""
      fi
   fi

   drive_state=$(fdisk -l | grep -c $drive)
   if [ $drive_state -eq 1 ]
      then
         echo ""
	 echo -e "\033[0;92m This is a new drive, formatting now \033[0m"
         echo ""
	 echo -e "n\n\n\n\n\n\nt\n8e\nw" | fdisk $drive
         echo ""
   elif [ $drive_state -ge 2 ]
      then
         echo -e "\033[0;92m This drive already has partitions, formatting now \033[0m"
	 echo -e "n\n\n\n\n\n\nt\n\n8e\nw" | fdisk $drive
         echo ""
   fi

   partprobe
   pvscan
   fdisk -l | grep /dev/sd > fdisk_output3
   if diff fdisk_output2 fdisk_output3
   then
      echo -e "\033[0;92m fdisk has ** not ** successfully partitioned the disk, script is now going to exit \033[0m"
      echo ""
      exit 1
   else
      echo ""
      echo -e "\033[0;92m The new partition to be used to create the LVM will be: \033[0m"
      echo ""
      diff fdisk_output2 fdisk_output3 | sed '/:/d' | grep /dev/sd | cut -d' ' -f2
      echo ""
      echo -e "\033[0;92m If this is correct, press the ENTER key. If not press CTRL + C now! \033[0m"
      echo ""
      read -p ""
   fi
   partprobe
   pvscan
   partition=$(diff fdisk_output2 fdisk_output3 | sed '/:/d' | grep /dev/sd | cut -d' ' -f2)
   echo ""
   echo -e "\033[0;92m Running pvcreate command \033[0m"
   echo ""
   pvcreate $partition
   echo ""
   echo -e "\033[0;92m These are current existing Volume Groups, which one would you like
to use? (ONLY type the name) \033[0m"
   echo ""
   vgdisplay | grep 'VG Name'
   echo ""
   read -p '> ' vgname
   while [[ $vgname == *['!'@#\$%^\&*()_+]* ]]
   do
      echo -e "\033[0;92m Your name contains special characters, please only use normal characters \033[0m"
      read -p '> ' vgname
   done
   echo ""
   vgextend $vgname $partition
   echo ""
   pvscan
   echo ""
   echo -e "\033[0;92m These are the current existing Logical Volumes, which one would you like
to use? (ONLY type the path, but type the full path, eg: /dev/vg_name/lv_name) \033[0m"
   echo ""
   lvdisplay | grep 'LV Path'
   echo ""
   read -p '> ' lvpath
   echo ""
   echo -e "\033[0;92m Extending the current LVM. \033[0m"
   echo ""
   lvextend $lvpath $partition
   echo ""
   echo -e "\033[0;92m The current file system of the LVM is: \033[0m"
   echo ""
   get_filesystem=$(grep $lvpath /etc/fstab | tr -s ' ' | cut -d' ' -f3)

   if [ "$get_filesystem" == "" ]
   then
      cat /etc/fstab
      echo ""
      echo -e "\033[0;92m No filesystem was automatically detected, please inspect the /etc/fstab above and choose ext4, ext3, or xfs: \033[0m"
   else
      echo $get_filesystem
      echo ""
      echo -e "\033[0;92m If this is correct, press the 'y'(es) key, if not press enter the file system you would want to use, ext4, ext2, or xfs: \033[0m"
   fi

   echo ""
   read -p '> ' file_system_choice
   echo ""

   while [[ ! "$file_system_choice" =~ ^(y|ext4|ext3|xfs)$ ]]
   do
      echo -e "\033[0;92m You did not make a correct selection. Please either press 'y'(es) if the displayed filesystem was correct or enter a file system,
ext4, ext3 or xfs. \033[0m"
      echo ""
      read -p '> ' file_system_choice
   done

   if [[ "$file_system_choice" =~ ^(y|Y)$ ]]
   then
      file_system=$(grep $lvpath /etc/fstab | tr -s ' ' | cut -d' ' -f3)
   else
      file_system=$file_system_choice
   fi

   if [[ "$file_system" =~ ^(ext4|ext3)$ ]]
   then
      resize2fs $lvpath
   elif [ "$file_system" == "xfs" ]
   then
      xfs_growfs $lvpath
   else
      echo ""
      echo -e "\033[0;92m I don't know that file system, please run the file system extend command relevant
to the file system you are using for $lvpath! \033[0m"
      exit 1
   fi

   echo ""
   df -h > current_space2
   if diff -y current_space1 current_space2
   then
      echo -e "\033[0;92m The space was not added. Please double check the lvextend or resize command, exiting the script! \033[0m"
      exit 1
   else
      echo ""
      echo -e "\033[0;92m -------------------------------------------------------"
      echo -e "\033[0;92m ** Success! The new HDD space has been added to your exiting LVM! **"
      echo -e "\033[0;92m -------------------------------------------------------\033[0m "
      echo ""
   df -h
   echo ""
   fi
   rm -rf current_space1 current_space2
   rm -rf fdisk_output1 fdisk_output2 fdisk_output3


## Bash_menu wrong choice from main menu:

else
   echo -e "\033[0;92m ** You have not made a valid choice, exiting script ** \033[0m"
   exit 1
fi

}

## Which packages to install/run

if curl google.com >/dev/null; then
	clear
	check_os
	dialog_menu
else
	clear
	if [ -f /etc/redhat-release ]; then
		if [ yum list installed "dialog" >/dev/null 2>&1 ]; then
			echo -e "\033[0;92m The Dialog package is installed \033[0m"
			dialog_menu
		else
			bash_menu
		fi
	elif [ -f /etc/lsb-release ]; then
		if [ dpkg -l "dialog" >/dev/null 2>&1 ]; then
			echo -e "\033[0;92m The Dialog package is installed \033[0m"
			dialog_menu
		else
			bash_menu
		fi
	fi
fi



© 2018 GitHub, Inc.
Terms
Privacy
Security
Status
Help
Contact GitHub
API
Training
Shop
Blog
About
Press h to open a hovercard with more details.
