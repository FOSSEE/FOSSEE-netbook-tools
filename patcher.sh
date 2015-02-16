#!/bin/bash

export supertitle="FOSSEE Netbook Updates"
source easybashgui

#for Debugging
#set -x

logfile=patcher.log
testfile=robots.txt
files_in_all_commits=files_in_all_commits.txt
all_commits_one_liner_with_date=all_commits_one_liner_with_date.txt
all_commits_dates_with_file_paths=all_commits_dates_with_file_paths.txt
past_applied_commits=past_applied_commits.txt
local_updates=local_updates
unique_tags=unique_tags
	[ ! -d $unique_tags ] && mkdir -p $unique_tags
updated_file=updates.txt
INET_AVAILABLE=0

generic_return_code='Working offline. Select Ok to continue.'
return_code_1="Unknown error occured. $generic_return_code"
return_code_3="File I/0 error. $generic_return_code"
return_code_4="Network failure. Unable to connect internet. $generic_return_code"
return_code_5="SSL verification failure. Check system date. $generic_return_code"
return_code_7="Protocol error. $generic_return_code"
return_code_8="Server error. $generic_return_code"

function clean_up() {
	echo "================================ New iteration =============================">>$logfile
	date >> $logfile
	[ -f $testfile ] && rm -v $testfile>>$logfile
	[ -f $files_in_all_commits ] && rm -v $files_in_all_commits>>$logfile
	[ -f $all_commits_one_liner_with_date ] && rm -v $all_commits_one_liner_with_date>>$logfile
	[ -f $all_commits_dates_with_file_paths ] && rm -v $all_commits_dates_with_file_paths>>$logfile
	[ -f $past_applied_commits ] && rm -v $past_applied_commits>>$logfile
	[ -d $local_updates ] && rm -rvf $local_updates/>>$logfile

}

function check_internet() {
	#wait_for internet
	for each in {fossee.in,github.com};
	    do
		wget $each/$testfile &> /dev/null
		return_code=$?
		[ $return_code -eq 0 ] && INET_AVAILABLE=1 && break
		[ $return_code -eq 1 ] && alert_message $return_code_1 && break
		[ $return_code -eq 3 ] && alert_message $return_code_3 && break
		[ $return_code -eq 4 ] && alert_message $return_code_4 && break
		[ $return_code -eq 5 ] && alert_message $return_code_5 && break
		[ $return_code -eq 7 ] && alert_message $return_code_7 && break
	    done
	[ $return_code -eq 8 ] && alert_message $return_code_8
}


#fetch updates from github and show
function format_list_updates() {
	#make a local copy for editing
	[ $INET_AVAILABLE -eq 1 ] && git log  --pretty=\;\(%ar\)\;%d\;%s\;\(%h\) --no-walk --tags >\
				     $all_commits_one_liner_with_date
	for each in $(cat $all_commits_one_liner_with_date | cut -d ';' -f 5 | tr -d '(|)')
	    do
		files_in_each_commit=$(git show --first-parent --pretty="format:" --name-only $each)
		echo $files_in_each_commit | tr ' ' ',' >> $files_in_all_commits
	    done
	paste -d ';' $all_commits_one_liner_with_date \
                     $files_in_all_commits | \
		     awk 'BEGIN{FS=";";OFS=";"} {$1="[Not Updated]"} 1' > \
		     $all_commits_dates_with_file_paths
}

function select_updates() {
	for hash in $(cat unique_tags/*);
		do
			line=$(grep -on $hash $all_commits_dates_with_file_paths | cut -d ':' -f 1);\
		 	sed -i $line's/\[Not\ Updated\]/\[Updated\]/g' $all_commits_dates_with_file_paths;
		done

	selected_update=$(menu -w 1000 -h 550 "$(cat $all_commits_dates_with_file_paths | sed '/HEAD,\ origin/d' | \
                         cut -d ';' -f 1,2,3,4,5| tr ';' '  ' )" 2>&1)
			 [ $? -eq 1 ] && exit 0
	#get hash for selected_update
	selected_hash=$(echo $selected_update | grep -o \([0-9a-z]*\) | tr -d '(|)')
	selected_tag=$(echo $selected_update | grep -o \(tag:\ [A-Za-z0-9._-]*\) | sed 's/(tag:\ //' |sed 's/)//')
	#At a time only one version from associated tag
	find $unique_tags -iname $(echo $selected_tag | cut -d '-' -f 1)\* | grep '' && [ $? -eq 0 ] && \
			rm $(find $unique_tags -iname $(echo $selected_tag | cut -d '-' -f 1)\*)
	echo $selected_hash > $unique_tags/$selected_tag
	files_in_selected_hash=$(grep $selected_hash $all_commits_dates_with_file_paths | cut -d ';' -f6)
	#for more than one file
	for each_file in $(echo $files_in_selected_hash|tr ',' '\n');
		do
			mkdir -p $local_updates/$(dirname $each_file)
			git show $selected_hash:$each_file>$local_updates/$each_file
			echo "$selected_hash,$selected_tag">>$logfile
		done

}


function sudo_access() {
sudo -K
# The only place easybashgui fails. So adding separate functions for both tty(consoles) and pts(terminals)
# If tty not found, returns 1, so use zenity
tty | grep tty && \
while true
	do
		password=$(zenity --title "Enter your password to continue" --password)
		# zenity dialog button 'Cancel' returns 1, and 'Yes' returns 0.
		# Check for zenity 'Cancel' option
		[ $? -eq 1 ] && exit 0
		echo $password | sudo -S echo "test">/dev/null
		# If wrong password then brek
		[ $? -eq 0 ] && break
	done


tty | grep pts  && \
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

}




function apply_updates() {
	question "Do you want to apply the selected update? This will affect the following file(s): '/$files_in_selected_hash'" 2>&1
	[ $? -eq 1 ] && exit 0
	for each_file in $(echo $files_in_selected_hash | tr ',' '\n');
		do
			echo "##### applying updates #####">>$logfile
			mv -v $local_updates/$each_file /$each_file>>$logfile
		done
	question "Update done. Select 'Ok/Yes' to revisit update selection menu. Select 'Cancel/No' to 'Quit' this program"
	[ $? -eq 1 ] && exit 0
	call_functions
}

function call_functions() {
#Function calls
	clean_up
#	check_internet
#	format_list_updates
#	select_updates
	sudo_access
#	apply_updates
}

# __init__
call_functions
