#!/bin/bash

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
# This program is intended to write/copy images to any media or drive.

# This script depends on 'easybashgui'.
# The password function has extra dependency on 'zenity' & 'dialog'
# programs, which can be modified to work with other libraries too

source easybashgui

#Paths
fb1=/etc/X11/xorg.conf.fb1
xorg=/etc/X11/xorg.conf

function sudo_access() {
# Clear remember password
sudo -K
# The only place 'easybashgui' fails. So adding separate functions for both tty(consoles)
# and pts(terminals). If tty not found, it returns 1, and 'zenity' is used
if [ ! -z $(pidof X) ] ; then

while true
        do
                password=$(zenity --title "Enter your password to continue" --password)
                # zenity dialog button 'Cancel' returns 1, and 'Yes' returns 0.
                [ $? -eq 1 ] && exit 0
                echo $password | sudo -S echo "test">/dev/null
                # If wrong password then brek
                [ $? -eq 0 ] && break
        done
else

while true
        do
                password=$(dialog --title "Password" \
                  --clear \
                  --passwordbox "Enter your password" 10 30 \
                  --stdout)
        [ $? -eq 1 ] && exit 0
                echo $password | sudo -S echo "test">/dev/null
                # If wrong password then brek
                [ $? -eq 0 ] && break
        done
fi
}

# ==================================================================================

function try_lightdm_restart() {
        while true;
	 do
           	sudo restart lightdm
                [ $(service lightdm status|grep -o start) == 'start' ] && break
        done
	killall probe_hdmi.sh
}


# ==================================================================================

function probe_hdmi() {

kernel_resolution=$(cat /sys/class/graphics/fb1/modes | cut -d ':' -f2 | cut -d '-' -f1)

if [ $kernel_resolution == '1024x720p' ] && [ ! -f $xorg ]; then
return_code_A=$(question -w 800 -h 200 "There are two possible settings, A and B. You are in Setting-(A) (default setting): You may need to connect the HDMI/HDMI-to-VGA cable to netbook and restart once.\\n\\nHDMI might work in setting-(A) with thick bottom bar.\\n The setting-(B) will make your bottom panel unvailable on netbook screen, but HDMI might work in full screen. \\nYour desktop will be reloaded, hence save your files. Select 'Ok' to try setting-(B), select 'Cancel' to continue Setting-(A). \\nYou may change from setting-(B) to setting-(A) anytime by revisiting this application" 2>&1)
[ $return_code_A -eq 1 ] &&  exit 0
sudo cp -v $fb1 $xorg
try_lightdm_restart
exit 0
fi

# ---------------------------------------------------------------------------------

if [ $kernel_resolution == '1024x720p' ] && [ -f $xorg ]; then
return_code_B=$(question -w 350 -h 250 "You are in setting-(B): Do you wish to change to setting-(A)(default setting)? Select 'Ok' to switch to setting-(A). Select 'Cancel' to continue setting-(B)" 2>&1)
[ $return_code_B -eq 1 ] && exit 0
sudo rm -v $xorg
try_lightdm_restart
exit 0
fi

}

sudo_access
probe_hdmi
