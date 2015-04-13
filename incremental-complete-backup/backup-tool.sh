#!/bin/bash
#***********************************************#
#  Gui tool to create backups of FOSSEE laptop  #
#	to external storage media.              #
#                                               #
#***********************************************#

#functions()
# --------------------------------------------------------- #
# selection_menu ()                                         #
# shows the menu with two options.                          #
# Parameter: $1(title) $2(option1) $3(option2)              #
# change the value of $result to 1 or 2 according to option #
# selected.                                                 #
# --------------------------------------------------------- #
selection_menu() {
choice="$(zenity --width=600 --height=200 --list --radiolist --title="$1" --text "<b>Choose :</b> " --hide-header --column "selection"  --column "options" FALSE "$2" FALSE "$3")"

case "${choice}" in
    $2 )
        result="1"
        ;;
    $3 )
        result="2"
        ;;
esac
}
###################################################################################
# Execution starts here.

zenity --width=600 --height=200 --info --text "You need an 8Gb or above external storage device (sdcard /pendrive) to continue"
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

