#! /bin/sh

#Enviroment variables
boot_part=/dev/mtd4
rootfs_mtd_num=5
rootfs_part=/dev/mtd${rootfs_mtd_num}
ubuntu_dir=/nand_previous
kernel_image=/sd_card/uzImage.bin
ramdisk_image=/sd_card/initrd.img


#This is the recovery script used to re-install or recover the FOSSEE-OS.

#This is the initial function which is called, also this is the first screen that comes up in this process.
#Seq-1
image()
{
echo ""
echo ""
echo "  ==========================================================================================================================="
echo "||                                                                                                                           ||"
echo "||                                                                                                                           ||"
echo "||                                                                                                                           ||"
echo "||                                                     FOSSEE NOTEBOOK                                                       ||"
echo "||                                                       INSTALLER                                                           ||"
echo "||                                                                                                                           ||"
echo "||                                                                                                                           ||"
echo "||                                                                                                                           ||"
echo "  ===========================================================================================================================" 
echo ""
echo ""
echo ""
}

init()
{
printf "\t\tPress [A/a] to go to advanced options or [I/i] to re-install the FOSSEE-OS?"
read -s -n 1 choose_key
if [ $choose_key = "A" ] || [ $choose_key = "a" ]; then
    advanced
elif [ $choose_key = "I" ] || [ $choose_key = "i" ]; then
    install
elif [ $choose_key = "" ] || [ $choose_key = " " ]; then
    echo ""
    echo -e "\t\tPlease enter a valid choice"
    init
else
    echo ""
    echo -e "\t\tPlease enter a valid choice"
    init
fi
}

#This function validates the users choice of re-installation.
#Seq- 1->I->2

install()
{
echo ""
echo ""
printf "\t\tDo you want to continue with the installation?\n"
printf "\t\tPress [Y/y] to continue, [N/n] to go back to the previous menu."
read -s -n 1 key
if [ $key = "Y" ] || [ $key = "y" ]; then
    installation
elif [ $key = "N" ] || [ $key = "n" ]; then
    /mnt/busybox clear
    image
    init
else
    echo ""
    echo -e "\t\tPlease enter a valid choice"
    install
fi
}

#This function is where the actual installation is done.
#Seq- 1->I->2->3

installation()
{
    #Detect the no. of partitions on the SD Card.
    #If it contains a single partition, then continue, otherwise copy the contents of ext4 to nand_previous.
	echo ""
        echo ""
	echo -e "\t\tThe installation is underway, do not exit..."
	# exit 0
	mkdir $ubuntu_dir
   
   # This part is taken care of in lib/debian-installer/menu file.
   # mkdir /sd_card  
   # mount /dev/mmcblk0p1 /sd_card

	if [ $(echo $?) -eq 0 ]; then
	    flash_erase $rootfs_part 0 0 > /dev/null
	else 
	    echo -e"\t\tSD card not mounted"
	    sleep 3
	    exit 0
	fi
	ubiattach /dev/ubi_ctrl -m $rootfs_mtd_num > /dev/null
	ubimkvol /dev/ubi0 -N ubuntu-rootfs -m > /dev/null
	if [ $(echo $?) -eq 0 ]; then
	    mount -t ubifs ubi0_0 $ubuntu_dir
	else
	    echo -e "\t\tubimkvol failed"
	    sleep 3
	    exit 0
	fi 
	#Insert progress bar here.
	#Check the no. of partitions on the SD card. 1?regular-backup!incremental-backup.

	part_no_two=$(ls /dev/mmcblk0* | echo $part_no_two | cut -d' ' -f3) #Check for the second partition on the SD card.
	if [ $part_no_two ='' ]; then
	    sh /mnt/bar /sd_card/fossee-os.tar.gz | tar xzpf - -C /nand_previous
	    sync
	else
	    mount /dev/mmcblk0p2 /tmp
	    cp -a /tmp /nand_previous
	    umount /dev/mmcblk0p2

	umount $ubuntu_dir
   # /bin/sh
	echo "" 
	echo -e "\t\tInstallation complete."
	sleep 2
	echo ""
	umount /dev/mmcblk0p1
	printf "\t\tPress ENTER to restart.[ Please remove the SD card first ]"
	read read_restart
	if $read_restart; then
	    reboot
	else
	    echo "It shouldn't come here"
	fi

    
}
#This functions presents the user with advanecd options where he/she can backup their data from previous installation or repair the current installation through shell prompt.
#Seq- 1->A->2

advanced()
{
#This will detect the previous mtd partiton.
prev_mtd_part=$(cat /proc/mtd | grep "ubuntu-rootfs" | cut -b 4) 
echo ""
echo ""
echo -e "\t\tTrying to access previous installation"
printf "\t\tMounting SD card"
#mkdir /sd_card
#mount /dev/mmcblk0p1 /sd_card
for i in `seq 1 2`
  do
    printf "."
    sleep 1
  done
echo ""
echo -e "\t\tYou may backup your essential files and folders or repair your previous installation.\n
\t\tThis will now fallback to a command prompt"
#This will take the user to his previous installation.
mkdir -p /nand_previous
ubiattach /dev/ubi_ctrl -m $prev_mtd_part
#ubimkvol /dev/ubi0 -N ubuntu-rootfs -m
mount -t ubifs ubi0_0 /nand_previous 
/mnt/busybox clear
/bin/sh
/mnt/busybox clear
reinstall
}

#This function is used for re-installating the OS after successfully backing-up the users data.
#Seq- 1->A->2->3

reinstall()
{
echo ""
echo ""
image
printf "\t\tDo you want to reinstall the FOSSEE operating system?[Y/N]"
read RET
if [ "$RET" = "Y" ] || [ "$RET" = "y" ]; then
    umount /nand_previous
    umount /dev/mmcblk0p1
    ubidetach -d 0 /dev/ubi_ctrl 
    rmdir /nand_previous
    rmdir /sd_card
    install
elif [ "$RET" = "N" ] || [ "$RET" = "n" ]; then
    umount /nand_previous
    printf "\t\tPress ENTER to reboot. [ Please remove the SD card first ]"
    read $restart_key
    if $restart_key; then
        reboot
    else
        echo "It should not come here."
    fi
else
    echo "Please enter a valid choice"
    reinstall
fi
}
image
init
   
