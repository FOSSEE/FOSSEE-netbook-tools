#This is the recovery script used to re-install or recover the FOSSEE-OS.

#This is initial function which is called, also this is the first screen that comes up in this process.
#Seq-1

init()
{
echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "|                                                                                                                                  | "
echo "|                                               FOSSEE NOTEBOOK                                                                    | "
echo "|                                                  INSTALLER                                                                       | "
echo "|                                                                                                                                  | "
echo "|                                                                                                                                  | "
echo "|                                                                                                                                  | "
echo "------------------------------------------------------------------------------------------------------------------------------------ "
echo "\n"
echo "\n"
echo "\n"
printf "Press [A/a] to go to advanced options or [I/i] to re-install the FOSSEE-OS?"
read choose_key
if [ $choose_key == "A" ] || [ $choose_key == "a" ]; then
    advanced
elif [ $choose_key == "I" ] || [ $choose_key == "i" ]; then
    echo "Installing a fresh copy of FOSSEE-OS operating system in ... \t" #Include the time remaining
    for i in {5..1}
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
printf " Do you want to continue with the installation? Press [Y/y] to continue, [N/n] to go back to the previous menu.\t"
read key
if [ $key == "Y" ] || [ $key == "y" ]; then
    installation
elif [ $key == "N" ] || [ $key == "n" ]; then
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
    
}

#This functions presents the user with advanecd options where he/she can backup their data from previous installation or repair the current installation through shell prompt.
#Seq- 1->A->2

advanced()
{
    clear
    echo "\tTrying to access previous installation"
    printf "\tMounting SD card"
    for i in {1..10}
    do
	printf "."
	sleep 1
    done
echo ""
echo "You may backup your essential files and folders or repair your previous installation. This will now fallback to a command prompt"
sleep 7
echo "fallback to terminal"
reinstall
}

#This function is used for re-installating the OS after successfully backing-up the user's data.
#Seq- 1->A->2->3

reinstall()
{
printf "Do you want to reinstall the FOSSEE operating system?[Y/N]"
read RET
if [ "$RET" = "Y" ] || [ "$RET" = "y" ]; then
    install
elif [ "$RET" = "N" ] || [ "$RET" = "n" ]; then
    echo "Remove SD card and try your old installation"
    exit
else
    echo "Please enter a valid choice"
fi
}

init   
