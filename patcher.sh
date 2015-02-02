#!/bin/bash

INET_AVAILABLE=0

#<check internet> handles both network and internet availability
function check_internet() {
	for each in {fossee.in,spoken-tutorial.org}; do
		wget $each/robots.txt &> /dev/null
		return_code=$?
		[ $return_code -eq 0 ] && INET_AVAILABLE=1
		[ $return_code -eq 4 ] && echo 'Please connect to internet!'
		[ $return_code -eq 5 ] && echo 'Please check the system date!'
		[ $return_code -eq 8 ] && echo 'Server error'
	done
	[ $INET_AVAILABLE -eq 0 ] && exit 0
}

#<fetch updates> from github and show
function fetch_updates() {
	UPDATES=$(git fetch &> /dev/null && \
	        comm --nocheck-order -3 \
	        <(git log --all --pretty="%H")\
	        <(git log --pretty="%H"))
	git show -s --format=%B $UPDATES
}


check_internet
fetch_updates
