#!/usr/bin/env bash

## Checks health and heartbeat for other server
### Sean McArdle Nov 2013

# parse options, set global variables
verbose=false
report=false

notify_cpu=false
notify_disk=false
notify_service=false

while getopts ":vhr" arg; do
    case "${arg}" in
	v)
	    verbose=true
	    ;;
	h)	    
	    show_help
	    ;;
	r)
	    report=true
	    ;;
	*)
	    ;;
    esac
done

# functions

function show
{
    if $verbose ; then
	echo $1
    fi
}

function show_help
{
    echo "You need help"
    exit
}


# Load config
if [ -f check.conf ]; then
    . check.conf
else
	echo "config.sh file not found, exiting"
	exit 1
fi


ping -c 2 $target > /dev/null

if [ $? -eq 0 ]; then
    
  # target is alive, check cpu
  show "host $target is up"
  cpu=`ssh $ssh_user@$target top -bn 4 | grep Cpu\(s\) | awk '{print $5}' | cut -d % -f 1 | awk '{sum+=100-$1}END{print sum/NR}'`
  if [[ $(echo "if (${cpu} > ${cpu_thresh}) 1 else 0" | bc) -eq 1 ]]; then
      show "cpu usage high: $cpu"
  else
      show "cpu usage low: $cpu"
  fi


  # check % used disk space per partition
  disk=`ssh $ssh_user@$target df -h | tail -n +2 | awk '{print $5 ":" $6}'`
  for partition in ${disk}; do
    percent=`echo $partition | cut -d % -f 1`

    if [[ $(echo "if (${percent} > ${disk_thresh}) 1 else 0" | bc) -eq 1 ]]; then
      show "disk usage above $disk_thresh%: $partition"
      notify_disk=true
    else
      show "disk is fine: $partition"
    fi
  done


  # check for required services
  
  
  # if verbose, print values
  
  if $report ; then
      echo "-- This is what I know --"
      echo "target machine: $target"
      echo "ssh user: $ssh_user"
      echo "cpu usage: $cpu"
      echo "disk usage: $disk"
      echo "services: $services"
  fi


else
    show "cannot reach host $target!"
fi

