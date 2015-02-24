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
export supertitle="Probe HDMI"

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

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
                password=$(zenity --title "Probe HDMI" --password)
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
           	sudo service lightdm restart
	        grep "(EE) FBDEV(0): mmap fbmem: Invalid argument" /var/log/Xorg.0.log
		return_code_grep=$?
              # [ $(service lightdm status|grep -o start) == 'start' ] && break
	      # If return code is 0 means the error exist in Xorg file, i.e, Xorg failed,
	      #	 so do restart, if its 1 means X might have restarted properly
                [ $return_code_grep -eq 1 ] && break
        done
	#killall probe_hdmi.sh
}


# ==================================================================================

function probe_hdmi() {

kernel_resolution=$(cat /sys/class/graphics/fb1/modes | cut -d ':' -f2 | cut -d '-' -f1)

if [ $kernel_resolution == '1024x720p' ] && [ ! -f $xorg ]; then

message -w 500 -h 400 "There are two possible settings, A and B. You are in Setting-A (default setting).\\nIt is recommended to connect HDMI/HDMI-to-VGA cable to netbook and restart. HDMI might work with thick bottom bar. You can also use this application through console by typing 'probehdmi'.\\n Select 'Ok' to continue"


return_code_A=$(question -w 600 -h 300 "If setting-A doesn't work, you may try setting-B. The setting-B will make your bottom panel unavailable on netbook screen, but HDMI might work in full screen mode. Your desktop will be reloaded.\\nSelect 'Ok' to try setting-B, select 'Cancel' to continue Setting-A. \\nYou may change from setting-B to setting-A anytime by revisiting this application or by restarting the netbook" 2>&1)

[ $return_code_A -eq 1 ] &&  exit 0
sudo cp -v $fb1 $xorg
try_lightdm_restart
exit 0
fi

# ---------------------------------------------------------------------------------

if [ $kernel_resolution == '1024x720p' ] && [ -f $xorg ]; then
return_code_B=$(question -w 350 -h 250 "You are in setting-B.\\nDo you wish to switch to setting-A(default setting)? Select 'Ok' to switch to setting-A(desktop will be reloaded). Select 'Cancel' to continue setting-B" 2>&1)
[ $return_code_B -eq 1 ] && exit 0
sudo rm -v $xorg
try_lightdm_restart
exit 0
fi

}

sudo_access
probe_hdmi
