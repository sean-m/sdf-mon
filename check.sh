#!/usr/bin/env bash

# Checks health and heartbeat for other server

# Load config
if [ -f check.conf ]; then
    . check.conf
else
	echo "config.sh file not found, exiting"
	exit 1
fi


notify_cpu=false
notify_disk=false
notify_service=false


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


  # check % used disk space per partition
  disk=`df -h | tail -n +2 | awk '{print $5 ":" $6}'`
  for partition in ${disk}; do
    percent=`echo $partition | cut -d % -f 1`

    if [[ $(echo "if (${percent} > ${disk_thresh}) 1 else 0" | bc) -eq 1 ]]; then
      echo "disk usage above $disk_thresh: $partition"
      notify_disk=true
    else
      echo "disk is fine: $partition"
    fi
  done


  # check for required services
  


else
    echo "cannot reach host $target!"
fi

