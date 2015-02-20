#!/bin/bash

# For title of each Window
export supertitle="FOSSEE Netbook Updates"
source easybashgui

# Intermediate files/directories. Will be removed after each interation
testfile=robots.txt
# Default is no internet
INET_AVAILABLE=0
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
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

function check_internet() {
	#wait_for internet
	wait_seconds 3
	for each in {google.com,github.com};
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
function pull_updates() {
	# If internet available just merge the changes (this won't update patches automatically)
	[ $INET_AVAILABLE -eq 1 ] && cd $DIR && git tag -l | xargs git tag -d && git pull>/dev/null 2>&1
}
check_internet
pull_updates
bash $DIR/patcher.sh
