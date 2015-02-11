#!/bin/bash

export supertitle="FOSSEE Netbook Updates"
source easybashgui

#for Debugging
#set -x

testfile=robots.txt
files_in_all_commits=files_in_all_commits.txt
all_commits_one_liner_with_date=all_commits_one_liner_with_date.txt
all_commits_dates_with_file_paths=all_commits_dates_with_file_paths.txt
past_applied_commits=past_applied_commits.txt
local_updates=local_updates
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

	[ -f $testfile ] && rm $testfile
	[ -f $files_in_all_commits ] && rm $files_in_all_commits
	[ -f $all_commits_one_liner_with_date ] && rm $all_commits_one_liner_with_date
	[ -f $all_commits_dates_with_file_paths ] && rm $all_commits_dates_with_file_paths
	[ -f $past_applied_commits ] && rm $past_applied_commits
	[ -d $local_updates ] && rm -rf $local_updates

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
	[ $INET_AVAILABLE -eq 1 ] && git log --format=\;\(%ar\)\;%s\;\(%h\) HEAD >\
				     $all_commits_one_liner_with_date
	for each in $(cat $all_commits_one_liner_with_date | cut -d ';' -f 4 | tr -d '(|)')
	    do
		files_in_each_commit=$(git show --first-parent --pretty="format:" --name-only $each)
		echo $files_in_each_commit | tr ' ' ',' >> $files_in_all_commits
	    done
	paste -d ';' $all_commits_one_liner_with_date \
                     $files_in_all_commits | \
		     awk 'BEGIN{FS=";";OFS=";"} {$1="[Not Updated]"} 1' > \
		     $all_commits_dates_with_file_paths
}

#function updates_


function select_updates() {
	#[ -f $updated_file ] && paste $past_applied_commits
	#menu $(cat $all_commits_dates_with_file_paths)
	selected_update=$(menu -w 1000 -h 550 "$(cat $all_commits_dates_with_file_paths | \
                         cut -d ';' -f 1,2,3,4| tr ';' '  ' )" 2>&1)
	#get hash for selected_update
	selected_hash=$(echo $selected_update | grep -o \([0-9a-z]*\) | tr -d '(|)')
	files_in_selected_hash=$(grep $selected_hash $all_commits_dates_with_file_paths | cut -d ';' -f5)
	#for more than one file
	for each_file in $(echo $files_in_selected_hash|tr ',' '\n');
		do
			mkdir -p $local_updates/$(dirname $each_file)
			git show $selected_hash:$each_file>$local_updates/$each_file
			echo $selected_hash;$files_in_selected_hash>>$updated_file
		done



}


#Function calls
clean_up
check_internet
format_list_updates
select_updates
