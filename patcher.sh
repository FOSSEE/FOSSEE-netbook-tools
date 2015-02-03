#!/bin/bash
source easybashgui


function check_internet() {
	for each in {fossee.in,github.com};
	    do
		wget $each/robots.txt &> /dev/null
	#	return_code=$?
		return_code=8
		[ $return_code -eq 0 ] && break
		[ $return_code -eq 1 ] && alert_message 'Generic error occured. Working offline. Select Ok to continue.' && break
		[ $return_code -eq 3 ] && alert_message 'File I/0 error. Check the permission of the present directory. Working offline. Select Ok to continue' && break
		[ $return_code -eq 4 ] && alert_message 'Network failure. Unable to connect internet. Working offline. Select Ok to continue.' && break
		[ $return_code -eq 5 ] && alert_message 'SSL verification failure. Check system date. Working offline. Select Ok to continue' && break
		[ $return_code -eq 7 ] && alert_message 'Protocol error. Working offline. Select Ok to continue.' && break
	    done

	[ $return_code -eq 8 ] && alert_message 'Server error. Working offline. Select Ok to continue.'
}

#fetch updates from github and show
function fetch_updates() {
	UPDATES=$(git fetch &> /dev/null && \
	        comm --nocheck-order -3 \
	        <(git log --all --pretty="%H")\
	        <(git log --pretty="%H"))
	git show -s --format=%B $UPDATES
}




check_internet
fetch_updates
