#! /bin/sh

#Enviroment variables
boot_part=/dev/mtd4
rootfs_mtd_num=5
rootfs_part=/dev/mtd${rootfs_mtd_num}
ubuntu_dir=/nand_previous
ubuntu_file=/sd_card/recovery.tgz
kernel_image=/sd_card/uzImage.bin
ramdisk_image=/sd_card/initrd.img


#This is the recovery script used to re-install or recover the FOSSEE-OS.

#This is initial function which is called, also this is the first screen that comes up in this process.
#Seq-1

init()
{
echo "-----------------------------------------------------------------------------------------------------------------"
echo "|                                                                                                     |"
echo "|                                      FOSSEE NOTEBOOK                                                |"
echo "|                                          INSTALLER                                                  |"
echo "|                                                                                                     |"
echo "|                                                                                                     |"
echo "|                                                                                                     |"
echo "------------------------------------------------------------------------------------------------------------------" 
echo ""
echo ""
echo ""
printf "Press [A/a] to go to advanced options or [I/i] to re-install the FOSSEE-OS?"
read choose_key
if [ $choose_key = "A" ] || [ $choose_key = "a" ]; then
    advanced
elif [ $choose_key = "I" ] || [ $choose_key = "i" ]; then
    echo "Installing a fresh copy of FOSSEE-OS operating system in ..." #Include the time remaining
    for i in 5 4 3 2 1;
    do
	echo "$i secs"
	sleep 1
    done
    install
else
    echo "Please enter a valid choice"
    init
fi
}

#This function validates his choice of re-installation.
#Seq- 1->I->2

install()
{
echo ""
printf " Do you want to continue with the installation? Press [Y/y] to continue, [N/n] to go back to the previous menu."
read key
if [ $key = "Y" ] || [ $key = "y" ]; then
    installation
elif [ $key = "N" ] || [ $key = "n" ]; then
    init
else
    echo "Please enter a valid choice"
    install
fi
}

#This function is where the actual installation is done.
#Seq- 1->I->2->3

installation()
{
    
   echo "The installation will take place here"
   # exit 0
   flash_erase $rootfs_part 0 0
   ubiattach /dev/ubi_ctrl -m $rootfs_mtd_num
   ubimkvol /dev/ubi0 -N ubuntu-rootfs -m
   mount -t ubifs ubi0_0 $ubuntu_dir
   mkdir /tmp/recovery-img
   mkdir /tmp/recovery-contents 
   tar xvvf $ubuntu_file -C /tmp/recovery-image
   mount /tmp/recovery-image/recovery.img /tmp/recovery-contents
   cp -a /tmp/recovery-contents/* $ubuntu_dir
   sync
  # mode=$(fbset | grep geometry | cut -c5- | cut -d\ -f2,3 | tr \ x)
  # sed -i "s/MODE_ANY/$mode/g" ${ubuntu_dir}/etc/X11/xorg.conf
   sync

   umount $ubuntu_dir
  #  /bin/sh 
   echo "Installation complete"
   reboot
    
}
#This functions presents the user with advanecd options where he/she can backup their data from previous installation or repair the current installation through shell prompt.
#Seq- 1->A->2

advanced()
{
echo "Trying to access previous installation"
printf "Mounting SD card"
mkdir /sd_card
mount /dev/mmcblk0p1 /sd_card
for i in `seq 1 10`
  do
    printf "."
    sleep 1s
  done
echo ""
echo "You may backup your essential files and folders or repair your previous installation. This will now fallback to a command prompt"
#This will take the user to his previous installation.
mkdir /nand_previous
ubiattach /dev/ubi_ctrl -m 5
mount -t ubifs ubi0_0 /nand_previous 
sleep 7
/bin/sh
umount /nand_previous
reinstall
}

#This function is used for re-installating the OS after successfully backing-up the users data.
#Seq- 1->A->2->3

reinstall()
{
printf "Do you want to reinstall the FOSSEE operating system?[Y/N]"
read RET
if [ "$RET" = "Y" ] || [ "$RET" = "y" ]; then
    install
elif [ "$RET" = "N" ] || [ "$RET" = "n" ]; then
    printf "Remove SD card. This machine will reboot in..."
    for i in 4 3 2 1
    do
        echo "$i secs"
        sleep 1
    done
    reboot
else
    echo "Please enter a valid choice"
    reinstall
fi
}

init
   
