#!/bin/bash

export supertitle="FOSSEE Netbook Updates"
source easybashgui
selected_update=''

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
		[ $return_code -eq 0 ] && list_updates && exit 0
		[ $return_code -eq 1 ] && alert_message $return_code_1 && break
		[ $return_code -eq 3 ] && alert_message $return_code_3 && break
		[ $return_code -eq 4 ] && alert_message $return_code_4 && break
		[ $return_code -eq 5 ] && alert_message $return_code_5 && break
		[ $return_code -eq 7 ] && alert_message $return_code_7 && break
	    done
	[ $return_code -eq 8 ] && alert_message $return_code_8
}


#fetch updates from github and show
function list_updates() {
	git log --format=%h\;\[%ar\]\;%s HEAD > /tmp/1 #make a local copy for editing
	selected_update=$(menu -w 900 -h 500 "$(git pull >/dev/null && git log --format=\[%ar\]\ \ \ %s\ \[%h\] HEAD)" 2>&1)
	selected_commit_hash=$(echo $selected_update | rev | cut -c -9 | rev | tr -d '[|]')
	echo $selected_commit_hash
}


#Function call
check_internet #if success, it call fetch_updates(), else call list_updates()
