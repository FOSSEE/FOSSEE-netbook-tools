#!/bin/bash

# A simple script to control screen brightness using 'notify send'
# copyright Srikant Patnaik
# GNU GPLv3

# Three brightness modes
brightness_max=250
brightness_med=160
brightness_low=80

# A file to store previous brightness value
status_file=/tmp/previous_brightness

# If running for first time, then create the status file with med value for brightness
if [ ! -f $status_file ];
then
        echo $brightness_med > $status_file
fi

previous_brightness=$(cat $status_file)

if (( "$previous_brightness" == "80" ));
then
	echo $brightness_med > /sys/class/backlight/pwm-backlight.0/brightness
        #notify-send "medium brightness"
	echo -n "medium brightness" | osd_cat --font='-b&h-lucida-medium-r-normal-*-34-*-*-*-p-*-iso10646-1'  --color=green  --pos=top 	   --align=right   --offset=50   --indent=50 -d 1
        echo $brightness_med > $status_file

elif (( "$previous_brightness" == "160" ));
then
	echo $brightness_max > /sys/class/backlight/pwm-backlight.0/brightness
        #notify-send "full brightness" 
	echo -n "full brightness" | osd_cat --font='-b&h-lucida-medium-r-normal-*-34-*-*-*-p-*-iso10646-1'  --color=green  --pos=top 	   --align=right   --offset=50   --indent=50 -d 1
        echo $brightness_max > $status_file
else
	echo $brightness_low > /sys/class/backlight/pwm-backlight.0/brightness
      # notify-send "low brightness"
	echo -n "low brightness" | osd_cat --font='-b&h-lucida-medium-r-normal-*-34-*-*-*-p-*-iso10646-1'  --color=green  --pos=top 	   --align=right   --offset=50   --indent=50 -d 1
        echo $brightness_low > $status_file
fi
