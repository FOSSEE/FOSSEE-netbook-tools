#!/bin/bash

# Runs only one time
export PREV_NUM_DEVICES=$(usb-devices | grep Product | wc -l)

while true
	do
		PRESENT_NUM_DEVICES=$(usb-devices | grep Product | wc -l)
		if [ "$PRESENT_NUM_DEVICES" -gt "$PREV_NUM_DEVICES" ]
		then
			echo $PRESENT_NUM_DEVICES inside if
		fi
		export PREV_NUM_DEVICES=$PRESENT_NUM_DEVICES
		sleep 1;
	done


