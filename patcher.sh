#!/bin/bash

export supertitle="FOSSEE Netbook Updates"
source easybashgui

files_in_all_commits=files_in_all_commits.txt
all_commits_one_liner_with_date=all_commits_one_liner_with_date.txt
all_commits_dates_with_file_paths=all_commits_dates_with_file_paths.txt
past_applied_commits=past_applied_commits.txt
INET_AVAILABLE=0

[ -f $files_in_all_commits ] && rm $files_in_all_commits

generic_return_code='Working offline. Select Ok to continue.'
return_code_1="Unknown error occured. $generic_return_code"
return_code_3="File I/0 error. $generic_return_code"
return_code_4="Network failure. Unable to connect internet. $generic_return_code"
return_code_5="SSL verification failure. Check system date. $generic_return_code"
return_code_7="Protocol error. $generic_return_code"
return_code_8="Server error. $generic_return_code"


#The for loop may break in most of the time, unless there is an error in fossee.in
function check_internet() {
	#wait_for "Checking internet"
	for each in {fossee.in,github.com};
	    do
		wget $each/robots.txt &> /dev/null
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
	[ $INET_AVAILABLE -eq 1 ] && git log --format=\;\[%ar\]\;%s\;%h HEAD >\
				     $all_commits_one_liner_with_date
	for each in $(cat $all_commits_one_liner_with_date | cut -d ';' -f 4)
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


function select_applied_updates() {
	#[ -f $past_applied_commits ] && paste $past_applied_commits
	true
}

function clean_up() {

[ -f robots.txt ] && rm robots.txt
}


#Function calls
check_internet
format_list_updates
clean_up
