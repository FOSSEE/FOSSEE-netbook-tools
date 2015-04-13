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
sizeofDiskBeforeSDCARD=$(echo $password | sudo -S sfdisk -s\
| tail -1 | awk '{print $2}')
fi
}
# ------------------------------------------------------------#
# Prompt a dialog box asking user to connect the required     #
# media stores the size of disk after inserting the media     #
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


###################################################################################
# Execution starts here.

zenity --width=600 --height=200 --info --text "You need an 8Gb or above external storage device (sdcard /pendrive) to continue"
sudoAccess
removeSDCARD
insertSDCARD
SizeofSDCARD
selection_menu "Select Backup mode" "Incremental Backup" "Complete Backup"
case "${result}" in
    "1" ) #Incremental
        selection_menu "Incremental Backup options" "Continue with previous backup storage[if you have a previous incremental backup] " "Create a new backup by formating the storage"
        case "${result}" in
                "1" ) #continue rsync the storage
                        echo "rsync"
                        ;;
                "2" ) #start new rsync
                        echo "start inc Bkup"
                        ;;
        esac
        ;;#Complete 
    "2" )
        echo "Do a complete Backup"
        ;;
esac

