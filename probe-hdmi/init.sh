#!/bin/bash
export supertitle="Probe HDMI"
source easybashgui

INET_AVAILABLE=0
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# =====================================================================================
# Functions in order they get called                                                  #
# =====================================================================================

function check_internet() {
		wait_seconds 2
		wget -P $DIR http://google.com/robots.txt &> /dev/null
		return_code=$?
		[ $return_code -eq 0 ] && INET_AVAILABLE=1
		rm $DIR/robots.txt
}

# ======================================================================================

function pull_updates() {
	# If internet available just merge the changes
	[ $INET_AVAILABLE -eq 1 ] && cd $DIR && git pull>/dev/null 2>&1
}

check_internet
pull_updates
bash $DIR/probe-hdmi.sh&
