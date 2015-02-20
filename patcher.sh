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


# For title of each Window
export supertitle="FOSSEE Netbook Updates"
source easybashgui

# For global debugging(open flood gates)
#set -x

# Get the PATH of the running script
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
# For local debugging
logfile=$DIR/patcher.log
# Intermediate files/directories. Will be removed after each interation
testfile=robots.txt
files_in_all_commits=$DIR/files_in_all_commits.txt
all_commits_one_liner_with_date=$DIR/all_commits_one_liner_with_date.txt
all_commits_dates_with_file_paths=$DIR/all_commits_dates_with_file_paths.txt
past_applied_commits=$DIR/past_applied_commits.txt
local_updates=$DIR/local_updates
unique_tags=$DIR/unique_tags
	[ ! -d $unique_tags ] && mkdir -p $unique_tags
# Default is no internet
INET_AVAILABLE=0

# Its good to have them together
generic_return_code='Working offline. Select Ok to continue.'
return_code_1="Unknown error occured. $generic_return_code"
return_code_3="File I/0 error. $generic_return_code"
return_code_4="Network failure. Unable to connect internet. $generic_return_code"
return_code_5="SSL verification failure. Check system date. $generic_return_code"
return_code_7="Protocol error. $generic_return_code"
return_code_8="Server error. $generic_return_code"

# =====================================================================================
# Functions in order they get called                                                  #
# =====================================================================================

function clean_up() {
	echo "=========================== New iteration =========================">>$logfile
	date >> $logfile
	[ -f $testfile ] && rm -v $testfile>>$logfile
	[ -f $files_in_all_commits ] && rm -v $files_in_all_commits>>$logfile
	[ -f $all_commits_one_liner_with_date ] && rm -v $all_commits_one_liner_with_date>>$logfile
	[ -f $all_commits_dates_with_file_paths ] && rm -v $all_commits_dates_with_file_paths>>$logfile
	[ -f $past_applied_commits ] && rm -v $past_applied_commits>>$logfile
	[ -d $local_updates ] && rm -rvf $local_updates/>>$logfile

}

# ======================================================================================

function check_internet() {
	#wait_for internet
	for each in {fossee.in,github.com};
	    do
		wget -P $DIR $each/$testfile &> /dev/null
		return_code=$?
		[ $return_code -eq 0 ] && INET_AVAILABLE=1 && break
		[ $return_code -eq 1 ] && alert_message -w 300 -h 100 $return_code_1 && break
		[ $return_code -eq 3 ] && alert_message -w 300 -h 100 $return_code_3 && break
		[ $return_code -eq 4 ] && alert_message -w 300 -h 100 $return_code_4 && break
		[ $return_code -eq 5 ] && alert_message -w 300 -h 100 $return_code_5 && break
		[ $return_code -eq 7 ] && alert_message -w 300 -h 100 $return_code_7 && break
	    done
	[ $return_code -eq 8 ] && alert_message -w 300 -h 100 $return_code_8
}

# ======================================================================================

# Fetch updates if internet is available and formulate a CSV
function list_updates() {
	# If internet available just merge the changes (won't update patches automatically)
	#cd $DIR && [ $INET_AVAILABLE -eq 1 ] && git tag -l | xargs git tag -d && git pull &>/dev/null
	# Create CSV of commits with only tags( git tags are used to group similar patches)
	cd $DIR && git log  --pretty=\;\(%ar\)\;%d\;%s\;\(%h\) --no-walk --tags >\
				     $all_commits_one_liner_with_date
	# Find out files in each commit(with tag)
	for each in $(cat $all_commits_one_liner_with_date | cut -d ';' -f 5 | tr -d '(|)')
	    do
		files_in_each_commit=$(git show --first-parent --pretty="format:" --name-only $each)
		echo $files_in_each_commit | tr ' ' ',' >> $files_in_all_commits
	    done
	# Create a file with [Not Updated] flag on the first column for all the tags, we will
        # selectively change it to [Updated] based on previously applied patches(git tags)
	paste -d ';' $all_commits_one_liner_with_date \
                     $files_in_all_commits | \
		     awk 'BEGIN{FS=";";OFS=";"} {$1="[Not Updated]"} 1' > \
		     $all_commits_dates_with_file_paths
}

# ======================================================================================

function check_past_updates() {
	# If no new/old update available, just quit (Ignoring HEAD based tags to avoid confusion)
	no_updates=$(cat $all_commits_dates_with_file_paths | sed '/HEAD/d' | wc -c)
	[ $no_updates -eq 0 ] && alert_message -w 400 -h 250 "No available updates !!!" && exit 0
	# Look for previously applied updates(git tags)
	for hash in $(cat unique_tags/*);
		do
			line=$(grep -on $hash $all_commits_dates_with_file_paths | cut -d ':' -f 1);\
		 	sed -i $line's/\[Not\ Updated\]/\[Updated\]/g' $all_commits_dates_with_file_paths;
		done
}


# ======================================================================================

function select_updates() {
	# Show updates using 'menu' of 'easybashgui'
	selected_update=$(menu -w 900 -h 550 "$(cat $all_commits_dates_with_file_paths | sed '/HEAD/d' | \
                         cut -d ';' -f 1,2,3,4,5| tr ';' '  ' )" 2>&1)
			 [ $? -eq 1 ] && exit 0
	#get hash for selected_update
	selected_hash=$(echo $selected_update | grep -o \([0-9a-z]*\) | tr -d '(|)')
	selected_tag=$(echo $selected_update | grep -o \(tag:\ [A-Za-z0-9._-]*\) | sed 's/(tag:\ //' |sed 's/)//')
}


# ======================================================================================

function generate_commit_files() {
	# At a time only one version from similar group of tags will be applied, for eg: AudioMic-1 and
        # AudioMic-2 (tags) can't be applied simultaneously as they might point to same file
	find $unique_tags -iname $(echo $selected_tag | cut -d '-' -f 1)\* | grep '' && [ $? -eq 0 ] && \
			rm $(find $unique_tags -iname $(echo $selected_tag | cut -d '-' -f 1)\*)
	# This will help identifying the unique tags among group of tags(commits/patches)
	echo $selected_hash > $unique_tags/$selected_tag
	# This for loop creates a copy of file(s) from given tag/commit
	files_in_selected_hash=$(grep $selected_hash $all_commits_dates_with_file_paths | cut -d ';' -f6)
	# For more than one file in a commit
	for each_file in $(echo $files_in_selected_hash|tr ',' '\n');
		do
			mkdir -p $local_updates/$(dirname $each_file)
			git show $selected_hash:$each_file>$local_updates/$each_file
			echo "$selected_hash,$selected_tag">>$logfile
		done
}

# ======================================================================================

function sudo_access() {
# Clear remember password
sudo -K
# The only place 'easybashgui' fails. So adding separate functions for both tty(consoles)
# and pts(terminals). If tty not found, it returns 1, and 'zenity' is used
tty | grep tty
if [ $? -eq 1 ]; then

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

# ======================================================================================

function apply_updates() {
	question -w 400 -h 150 "Do you want to apply the selected update? This will affect the following file(s): '/$files_in_selected_hash'" 2>&1
	[ $? -eq 1 ] && exit 0
	for each_file in $(echo $files_in_selected_hash | tr ',' '\n');
		do
			echo "##### applying updates #####">>$logfile
			[ ! -d /$each_file ] && mkdir -p $(dirname $each_file)>>$logfile
			mv -v $local_updates/$each_file /$each_file>>$logfile
		done
	question -w 400 -h 150 "Update done. Select 'Yes' to revisit update selection menu. Select 'Cancel' to 'Quit' this program"
	[ $? -eq 1 ] && exit 0
	main
}


# ======================================================================================

function spl_kernel_manage() {

	# environment variables
	kernel_image=$DIR/uzImage.bin
	ramdisk_image=$DIR/initrd.img
	boot_part=/dev/mtd4

	mkbootimg --kernel $kernel_image --ramdisk $ramdisk_image -o /tmp/boot.img
        sync
        echo 0 > /sys/module/yaffs/parameters/yaffs_bg_enable
        flash_erase $boot_part 0 0
        nandwrite -p $boot_part /tmp/boot.img
	sync
        echo 1 > /sys/module/yaffs/parameters/yaffs_bg_enable
}

# ======================================================================================

function main() {
#Function calls
	clean_up
	#check_internet
	list_updates
	check_past_updates
	select_updates
	generate_commit_files
	sudo_access
	apply_updates
	# Comment next function if you are not using FOSSEE netbook
	#spl_kernel_manage
}


# ======================================================================================

# __init__
main
