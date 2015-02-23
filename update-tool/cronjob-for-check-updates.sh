#!/bin/bash

# This script will be called by cronjob every hour


DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

cd $DIR

[ $(git fetch --tags --dry-run 2>&1 | wc -l) -ge 1 ] && \
notify-send "Updates available: menu -> FOSSEE-Tools -> FOSSEE-updates"

exit 0
