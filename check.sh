#!/usr/bin/env bash

# Checks health and heartbeat for another server

# Load config
if [ -f check.conf ]; then
    . check.conf
else
	echo "config.sh file not found, exiting"
	exit 1
fi


notify_cpu=false
notify_disk=false
notify_process=false


ping -c 4 $target > /dev/null

if [ $? -eq 0 ]; then
    
  # target is alive, check cpu
  echo "host $target is up"
  cpu=`top -bn 4 | grep Cpu\(s\) | awk '{print $5}' | cut -d % -f 1 | awk '{sum+=100-$1}END{print sum/NR}'`
  if [[ $(echo "if (${cpu} > ${cpu_thresh}) 1 else 0" | bc) -eq 1 ]]; then
  	echo "cpu usage high: $cpu"
 	else
 		echo "cpu usage low: $cpu"
  fi



else
    echo "cannot reach host $target!"
fi

