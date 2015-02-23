#!/bin/bash

# Run script daily at 4pm. To disable open 'crontab -e' as sudo/root and disable
# 0 16 * * * /opt/FOSSEE-netbook-tools/update-tool/cronjob-for-check-updates.sh

export DISPLAY=:0.0
export XAUTHORITY=$HOME/.Xauthority
user=$(echo $HOME|cut -d '/' -f3)
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd $DIR

# Just to find out the return code (The notify-send should not give output if
# internet is down)
return_text=$(git fetch --tags --dry-run 2>&1)
# Check for return code, it will be 0 if internet is available
[ $? -eq 0 ] && [ $(echo $return_text|wc -l) -ge 1 ] && \

sudo -u $user /usr/bin/notify-send -i "path/to//opt/FOSSEE-netbook-tools/update-tool/patcher.png" \
"FOSSEE Updates available" \
"menu -> FOSSEE-Tools -> FOSSEE-updates"

exit 0
