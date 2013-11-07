#!/usr/bin/env bash

## Checks health and heartbeat for other server
### Sean McArdle Nov 2013


# functions

function show
{
    if $verbose ; then
	echo $1
    fi
}

function show_help
{
    echo "Usage: check.sh [options]"
    echo "Options:"
    echo "   -h : show this help"
    echo ""
    echo "   -v : show verbose output"
    echo ""
    echo "   -r : show report when completed"
    echo ""
    exit
}


# parse options, set global variables
verbose=false
report=false

notify_link=false
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

# Load config
if [ -f check.conf ]; then
    . check.conf
else
    echo "config.sh file not found, exiting"
    exit 1
fi


# setup email distribution group
if [ ! -f ~/.mailrc ]; then
    echo "alias alertees $email_recipients" > ~/.mailrc
else
    grep -qi "alias alertees" ~/.mailrc
    if [ $? -eq 0 ]; then
	sed -i "/alias alertees/c\alias alertees $email_recipients" ~/.mailrc
    else
    	echo "alias alertees $email_recipients" > ~/.mailrc
    fi
fi


# test network link
ping -c 2 $target > /dev/null

if [ $? -eq 0 ]; then
    
  # target is alive, check cpu
  show "host $target is up"
  cpu=`ssh $ssh_user@$target top -bn 4 | grep Cpu\(s\) | awk '{print $5}' | cut -d % -f 1 | awk '{sum+=100-$1}END{print sum/NR}'`
  if [[ $(echo "if (${cpu} > ${cpu_thresh}) 1 else 0" | bc) -eq 1 ]]; then
      show "cpu usage high: $cpu"
      notify_cpu=true
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


  # check memory
  mem_reading=`ssh $ssh_user@$target free -m | tail -n +2`
  mem_total=`echo $mem_reading | awk '{print $2}'`
  mem_used=`echo $mem_reading | awk '{print $10}'`
  mem_percent_used=`echo "$mem_used $mem_total"| awk '{print $1/$2*100}' | cut -d . -f1`

#  show "mem_reading: $mem_reading"
  show "mem_total: $mem_total"
  show "mem_used: $mem_used"
  show "mem_percent_used: $mem_percent_used"

  if [[ $(echo "if (${mem_percent_used} > ${mem_thresh}) 1 else 0" | bc) -eq 1 ]]; then
      show "mem usage high: $mem_percent_used"
  else
      show "mem usage low: $mem_percent_used"
  fi



  # check for required services
  processes=`ssh $ssh_user@$target ps -A | tail -n +2 | awk '{print $4}'`
  services=""

  for proc in ${service_list}; do
      show $proc
      echo $processes | grep -q -e $proc
      val=$?
      show $val
      if [ $val -ne 0 ]; then
	  notify_service=true
	  services="$services $proc:off"
      else
	  services="$services $proc:on"
      fi
  done


else
    show "cannot reach host $target!"
    notify_link=true
fi



# send notifications if needed
dir=/tmp/.notifications
filename=$(date +%Y%m%d%H%M%S)-alert.log
send_alert=false

if [ ! -d /tmp/.notifications ]; then
    mkdir /tmp/.notifications
fi

alert_sub="alert: "


if $notify_link ; then
    alert_sub="$alert_sub link"
    echo "Cannot resolve $target" > $dir/$filename
    send_alert=true
else
    if $notify_cpu ; then
	alert_sub="$alert_sub cpu"
	send_alert=true
    fi

    if $notify_cpu ; then
	alert_sub="$alert_sub disk"
	send_alert=true
    fi

    if $notify_service ; then
	alert_sub="$alert_sub service"
	send_alert=true
    fi

    # write alert message
    echo "-- CPU Usage --" > $dir/$filename
    echo $cpu >> $dir/$filename
    echo "" >> $dir/$filename
    echo "-- Disk Usage --" >> $dir/$filename
    echo "disk" >> $dir/$filename
    echo "" >> $dir/$filename
    echo "-- Mem Usage --" >> $dir/$filename
    echo "total: $mem_total used: $mem_used percentage: $mem_percent_used" >> $dir/$filename
    echo "" >> $dir/$filename
    echo "-- Process Check" >> $dir/$filename
    echo "$services" >> $dir/$filename
    echo "" >> $dir/$filename
fi

if $send_alert ; then
    if [ -s $dir/$filename ]; then
	    mail -S smtp=$smtp_server -s "${alert_sub} on ${target}" alertees < $dir/$filename
	    show "send $alert_sub email to $email_recipients"
    else
	for addr in ${email_recipient}; do
	    mail -S smtp=$smtp_server -s "${alert_sub} on ${target}" alertees < $dir/$filename
	    show "send link error to $email_recipients"
	done
    fi
fi


# if verbose, print values

if $report ; then
    echo "-- CPU Usage --" 
    echo $cpu 
    echo "" 
    echo "-- Disk Usage --" 
    echo "disk" 
    echo "" 
    echo "-- Mem Usage --" 
    echo "total: $mem_total used: $mem_used percentage: $mem_percent_used" 
    echo "" 
    echo "-- Process Check" 
    echo "" 
    echo "$services" 
fi


