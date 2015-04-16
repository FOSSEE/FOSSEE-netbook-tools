#!/bin/bash
#***********************************************#
#  Gui tool to create backups of FOSSEE laptop  #
#	to external storage media.              #
#                                               #
#***********************************************#

# functions()
# ###########
# ------------------------------------------------------------#
# selection_menu ()                                           #
# shows the menu with two options.                            #
# Parameter: $1(title) $2(option1) $3(option2)                #
# change the value of $result to 1 or 2 according to option   #
# selected.                                                   #
# ------------------------------------------------------------#
selection_menu() {
choice="$(zenity --width=600 --height=200 --list --radiolist --title="$1" --text "<b>Choose :</b> " --hide-header --column "selection"  --column "options" FALSE "$2" FALSE "$3")"

case "${choice}" in
    $2 )
        result="1" # if option1 is selected.
        ;;
    $3 )
        result="2" # if option2 is selected.
        ;;
esac
}
# ------------------------------------------------------------#
# sudoAccess ()                                               #
# get the sudo password from user via zenity window and       #
# stores in a global variable ($password).                    #
#                                                             #
# ------------------------------------------------------------#
sudoAccess() {
# Remove any previous sudo passwords
sudo -K
# In case of wrong password, else condition will fail(return 1)
# and executes from beginning
while true
do
# Get password from user
password=$(zenity --title "Enter your password to continue" --password)
# zenity dialog button 'Cancel' returns 1, and 'Yes' returns 0.
# Check for zenity 'Cancel' option
if [ $? -eq 1 ]
then
exit 0
else
# sending user entered password to 'echo' command to verify
# password, if wrong it will repeat from beginning
echo $password | sudo -S echo "test">/dev/null
if [ $? -eq 0 ]
then
break
fi
fi
done
}
# ------------------------------------------------------------#
# Prompt a dialog box asking user to remove all the external  #
# media and after that stores the size of disk without media  #
# on $sizeofDiskBeforeSDCARD                                  #
# ------------------------------------------------------------#
removeSDCARD() {
# The dialog box below will ask user to remove drive(sdcard)
zenity --question --title "Remove media" \
--text "Please remove your drive(sdcard) if connected,
then press YES to continue"
# Checking the return value of zenity dialog, same as previous function
if [ $? -eq 1 ]
then
exit 0
else
# This will return size of disk without our media
umount /media/$USER/*  # to unmount all external media.
sizeofDiskBeforeSDCARD=$(echo $password | sudo -S sfdisk -s\
| tail -1 | awk '{print $2}')
fi
}
# ------------------------------------------------------------#
# Prompt a dialog box asking user to connect the required     #
# media & stores the size of disk after inserting the media   #
# on $sizeofDiskAfterSDCARD.                                  #
# ------------------------------------------------------------#
insertSDCARD() {
# The dialog box below will ask user to insert sdcard
zenity --question --title "Insert media" --text "Now please insert your drive(sdcard) back,\
then press YES to continue"
# Checking the button selected in zenity dialog
if [ $? -eq 1 ]
then
exit 0
else
# sfdisk prints the total disk space in KB
sizeofDiskAfterSDCARD=$(echo $password | sudo -S sfdisk -s\
| tail -1 | awk '{print $2}')
fi
}
# ------------------------------------------------------------#
# Prompt a dialog box showing the size of detected media in   #
# GB. After calculating difference of sizeofDiskBeforeSDCARD  #
# and sizeofDiskAfterSDCARD                                   #
# ------------------------------------------------------------#
SizeofSDCARD() {
# verifying new device by finding difference in size
# before and after insertion
sizeSDCARDKbytes=$(($sizeofDiskAfterSDCARD - $sizeofDiskBeforeSDCARD))
# Converting into GB first
sizeSDCARD=$(echo "scale=2;$sizeSDCARDKbytes/1048576" | bc)
# Converting sizeSDCARD to integer, so as to use in conditional statement,
# if any card is detected it will go inside 'else' statement
if [ $(echo $sizeSDCARD |cut -f 1 -d '.') -eq 0 ]
then
zenity --info --title "Info" --text "No media found, please check and restart application"
exit 0
else
zenity --question --title "Info" --text "A device of $sizeSDCARD GB is detected, the size will be less \
than actual size of your device. Would you like to continue? \
Press 'YES' to continue or 'NO' to quit !"
# If 'NO' is selected in zenity dialog then exit
if [ $? -eq 1 ]
then
exit 0
fi
fi
}
# ------------------------------------------------------------#
# unmount the mounted partitions, create new partition table  #
# format 1st partition to vfat, 2nd to ext4 and mount under   #
# /mnt                                                        #
# ------------------------------------------------------------#
formatExternalmedia() {
umount /media/$USER/*
echo $password |sudo -S mkdir -p /mnt/boot /mnt/rootfs
echo -e "o\nn\np\n1\n\n+100M\nn\np\n2\n\n\nw"|sudo fdisk /dev/$dev_name  # delete old partition table and creating new
sudo mkfs.vfat /dev/$dev_name*1
sudo mkfs -t ext4 /dev/$dev_name*2
sudo mount /dev/$dev_name*1 /mnt/boot
sudo mount /dev/$dev_name*2 /mnt/rootfs
}

###################################################################################
# Execution starts here.

zenity --width=600 --height=200 --info --text "You need an 8GB or above external storage device (sdcard /pendrive) to continue"
sudoAccess
removeSDCARD
insertSDCARD
SizeofSDCARD
dev_name=`lsblk |head -2|tail -1|cut -d" " -f1` # tracking device name 
selection_menu "Select Backup mode" "Incremental Backup" "Complete Backup"
case "${result}" in
    "1" ) #Incremental
        selection_menu "Incremental Backup options" "Continue with previous backup storage[if you have a previous incremental backup] " "Create a new backup by formating the storage"
        case "${result}" in
                "1" ) # check for mac_id matching & proceed to rsync
                        rootfs_path=`mount | grep ext|cut -d" " -f3` # tracking the rootfs mount path
                        mac_id=`cat /sys/class/net/eth0/address`     # macid of the machine
                        if [ "$rootfs_path" == "" ] || [ ! -e $rootfs_path/opt/.Hw_addr.txt  ];
                        then # (no rootfs) or ( Hw_addr.txt not exists)
                            zenity --width=600 --height=100 --info --text "Your storage media doesnot contain matching backup from this machine"
                            exit
                        elif [ "$mac_id" == "$(cat $rootfs_path/opt/.Hw_addr.txt)" ]; # if macids are matching
                        then
                            echo "match found"
                            sudo rsync -latgrzpo --exclude='/tmp' --exclude='/dev' --exclude='/proc' --exclude='/sys' /opt $rootfs_path
                        else
                            zenity --width=600 --height=100 --info --text "Your storage media doesnot contain matching backup from this machine"
                            exit
			fi
                        ;;
                "2" ) #start new rsync
                        cat /sys/class/net/eth0/address > /opt/.Hw_addr.txt # storing mac_id b4 copy
                        formatExternalmedia
                        echo $rootfs_path
                        sudo rsync -latgrzpo --exclude='/tmp' --exclude='/dev' --exclude='/proc' --exclude='/sys' /opt /mnt/rootfs/
                        sync
                        sudo umount /mnt/*
                        sudo rm -rf /mnt/*
                        ;;
        esac
        ;;
    "2" ) #Complete 
        formatExternalmedia
        sudo tar -cpzf /mnt/rootfs/ubuntu13.04.tar --one-file-system /
        sync
        sudo umount /mnt/*
        sudo rm -rf /mnt/*
        ;;
esac
zenity --width=600 --height=100 --info --text "Done ! "
