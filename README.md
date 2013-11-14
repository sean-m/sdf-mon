sdf-mon
=======

Scripts to provide rudimentary heartbeat and health monitor of Debian servers.

## What is this?

This is intended to be a rudimentary server health monitoring tool when nothing
else is available. It was created out of desperation in an organization that
currently doesn't have adequate tools for monitoring Linux systems. It has been
developed with the intent of having no external dependencies, you should be
able to drop the script and config file on a system with BASH (Linux, OSX,
Cygwin) and begin getting health checks on another machine with minimal
tweaking.

This is in no way a replacement for monitoring systems such as Nagios, Cacti,
or Zabbix. **This is only intended for use when all you have is SSH and need to
keep an eye on a few servers.**

## Setup Process

### SSH User

The check.sh script makes use of SSH to facilitate connecting to the remote 
host. For information on what SSH is or how it works, read 
[this](https://en.wikipedia.org/wiki/Secure_Shell). The Reader's Digest 
summation of SSH is that it's a client/server utility that allows you to start 
a remote command line session on a remote (or local) machine over an encrypted 
connection. It offers lots of really awesome functionality and I do encourage 
you to follow [this link](https://en.wikipedia.org/wiki/Secure_Shell) to learn 
more.

There are two things you will need to setup SSH work: a user account on the 
target host, and an authorized SSH key for that account. Logged in as a user 
with root privileges (either as root or via 'sudo') the host that will be 
monitored, create a user account, I will use "simon" as the example user for 
the rest of this readme. In order to create this account on GNU/Linux you will 
execute:

`useradd -r -m -s /bin/bash simon`

The BSD's have their own commands for user creation: 
['adduser'](http://www.freebsd.org/cgi/man.cgi?query=adduser&sektion=8) and 
['pw'](http://www.freebsd.org/cgi/man.cgi?query=pw&sektion=8), so read through
the links if that fits your needs.

Now that simon exists, we can generate an SSH key pair and add them to simon's 
authorized_keys file. Logged into the host that will run the check.sh script as the script user, run the following command:

`ssh-keygen -b 2048 -C 'check.sh ssh key' -t rsa`

You will be prompted for a few options, accepting the defaults by pressing 
'Enter/Return' it will generate an SSH key pair with a 2048 bit key length and 
a comment that will help you identify the keys. It writes these out to
`~/.ssh/id_rsa` and `~/.ssh/id_rsa.pub`. The important things to know about
SSH keys is that the 'id_rsa' key is your private key and should be kept safe,
it should never leave the host computer unless you specifically intend it to,
'id_rsa.pub' is the public key that is distributed to the hosts that you wish
to remotely access via SSH. 

Now that we have some SSH keys, lets distribute the bits and start getting
health alerts. Now that simon has some SSH keys, we need to copy the public key
to the server we will be monitoring:

`scp ~/.ssh/id_rsa.pub simon@target-host:~/.ssh/authorized_keys`

This will allow our simon user to remotely log into the remote machine without
needing a password, instead it will check simon's public key with the list of
keys in it's 'authorized_keys' file, if they match and simon has the correct
private key, the encrypted SSH connection can be made.

So in case you've gotten lost in the details, here's what we've done: create a
user account called 'simon' on two computers, created ssh keys on computer 1,
copied the public key file from computer 1 to computer 2's 'authorized_keys'
file. The check.sh script will run on computer 1, and poll for health data from
computer 2, alerting us of problems with computer 2.

### Config File

Once SSH is configured and you need to start polling data it's time to tweak
a few features to fit your environment. The configuration for check.sh is
stored in the aptly named: check.conf. The configuration file is pretty
straight forward and comes with a few defaults, it looks something like this:

	## check.sh configuration options

	target=<hostname or IP>

	ssh_user=<username local to target machine>

	# value thresholds
	## a notification will be sent if threshold exceeded more than once
	cpu_thresh=90.00  #needs to be a float
	disk_thresh=90    #threshold for % free space
	mem_thresh=90     #threshold for % used memory

	# collection of services that must be running
	## space delimited
	service_list="apache2 mysqld cron" 

	smtp_server="smtp.hostname.mydomain"

	# collection of email notification recipients
	## space delimited
	email_recipient="larry.page@gmail.com"

The configuration file itself is written in BASH and as such, inherits BASH
syntax: no whitespace between variable name-assignment operator-value, in
line comments following '#' are ignored, number values don't require quotes. 

Just running through the values really quick, `target` is the hostname or IP of
the machine to be monitored, `ssh_user` is the user used to initiate the SSH
connections, threshold values are self explanatory. The last values deserve some explanation. 

`service_list` allows you to monitor running processes on the
target machine, it doesn't necessarily check the status of a service, simply
that a process exists in the process list (`ps -A`). Remotely checking the
status of a service reliably is tricky, on systems that implement the SysV Init
system, there is no standardization for what should be out from the `service
service_name status` command. The only standard output for this command is the
exit code, which can't be reliably trapped through SSH. On more modern systems
that implement the systemd init system, output for `systemctl status service_
name` is standardized but since systemd doesn't yet have market dominance in
the enterprise Linux space, it isn't implemented in this tool; maybe one day.

`smtp_server` and `email_recipient` are values that pertain to alert emails.
The first specifies the smtp relay server used to send the emails, this is only
necessary if you cannot send email through the default mx server for the
recipients domain, ie: "smtp.gmail.com" for "larry.page@gmail.com". The 
`email_recipient` value can contain multiple email addresses, separated by
whitespace. Email addresses without a domain name will assume to be local Linux
user accounts and will show up in system mail for that user: /var/spool/$USER.
The list of email addresses is read and written out to ~/.mailrc as a
distribution group each time. This was done so that recipients can see who the
alert was sent to as this could help coordinate the response effort.

The only rule other than those already listed is that check.conf needs to exist
in the same directory as check.sh. Nothing stops you from modifying the script
so that the config file path is passed to check.sh so you can maintain multiple
configurations for any number of servers you wish to monitor but that's up to
you.


### cron

Any task that must be repeated continuously at a predictable cadence in the
*nix world should be using cron. Cron has been around for decades and is a
staple for any experienced Linux/Unix admin, although it's been around forever
the documentation is cryptic and it's configuration syntax is rather foreign.
Despite that, for scheduled tasks, it is the right tool for the job.

I have check.sh configured so that it polls the target machine every 5 minutes.
To configure this, there are two commands you'll need to get familiar with
`crontab -l` and `crontab -e` (ok, one command two switches). `crontab -l`
lists all the cron jobs for the current user, `crontab -e` opens the users
cron configuration file in the default text editor. The cron configuration may
look something like this:

	# DO NOT EDIT THIS FILE - edit the master and reinstall.
	# (/tmp/crontab.psaTMA installed on Fri Nov  8 19:03:00 2013)
	# (Cronie version 4.2)
	*/1 * * * * /usr/bin/python /srv/www/sysmon/manage.py runtask getMeasures
	*/10 * * * * /usr/bin/python /srv/www/sysmon/manage.py runtask averageDay
	0 */1 * * * /usr/bin/python /srv/www/sysmon/manage.py runtask averageWeek
	0 */3 * * * /usr/bin/python /srv/www/sysmon/manage.py runtask averageMonth

If this looks cryptic to you, [don't panic](http://en.wikipedia.org/wiki/Don%27
t_Panic_(The_Hitchhiker%27s_Guide_to_the_Galaxy)#Don.27t_Panic), it's simpler
than it looks. Ignoring the lines that start with '#' we come to one that stars
with '*/1 * * * *', this provides the cadence information to cron, the part
folling it: '/usr/bin/python /srv/www/sysmon/manage.py...' is the command to
execute on on that schedule. I told you it was simple. 

So do construct a cron job that executes the check.sh script every 5 minutes we
need to take a closer look at the '*/1 * * * *' part, good info [here](https://
en.wikipedia.org/wiki/Cron#Predefined_scheduling_definitions). This is like our
list of email recipients, a collection of values separated by spaces, the info
graphic from [Wikipedia](https://en.wikipedia.
org/wiki/Cron#Predefined_scheduling_definitions) sums it up well:

	# * * * * *  command to execute
	# ┬ ┬ ┬ ┬ ┬
	# │ │ │ │ │
	# │ │ │ │ │
	# │ │ │ │ └───── day of week (0 - 6) (0 to 6 are Sunday to Saturday, or use names)
	# │ │ │ └────────── month (1 - 12)
	# │ │ └─────────────── day of month (1 - 31)
	# │ └──────────────────── hour (0 - 23)
	# └───────────────────────── min (0 - 59)

Since we want this script to run every 5 minutes, every day, every week, every
month, every day of the week; the first value should be `*/5`, followed by 
`* * * *`. We then follow that up with the full path to the check.sh file:

`*/5 * * * * /path/to/check.sh`

Putting that in simon's cron configuration with `crontab -e` is all that's
needed. I encourage you to read through the linked Wikipedia article and the
built-in documentation for cron `man cron`, a firm understanding of fundamental
Linux/Unix tools will serve you well as an administrator.

## Implementation Details

### mailx

The check.sh script uses the `mail` command to send email notifications. There
are several implementations of this and the script assumes the 'heirloom
mailx' implementation is the default 'mail' command. This differs from the BSD
and GNU mail implementations in a few ways, they all implement the same mail
features specified in the Posix Unix spec but heirloom provides the ability to
specify the outgoing smpt server by passing the hostname with a switch: `-S
smtp.my.domain`. It is the default mail client for Suse 12.x and is available
in the package repositories of most major distributions. To download and
compile the source when packages aren't available, look [here](http://heirloom.
sourceforge.net/index.html).

If you would rather use BSD or GNU mail, you need to remove the -S switch from the mail command used towards the end of check.sh.

### Top Parsing

Just a note, older versions of GNU top used '%' after some values in the
command's heading. Newer versions omit this breaking the way check.sh parses
top output for CPU usage. You'll need to remove the `cut` command and specify a
different offset in `awk` to capture the correct value, something like this:

original:  

    cpu=ssh $ssh_user@$target sleep 2s && top -d0.5 -bn 4 | grep Cpu\(s\) | awk '{print $5}' | cut -d % -f 1 | tail -n +2 | awk '{sum+=100-$1}END{print sum/NR}'

modified:

    cpu=ssh $ssh_user@$target sleep 2s && top -d0.5 -bn 4 | grep Cpu\(s\) | awk '{print $9}' | tail -n +2 | awk '{sum+=100-$1}END{print sum/NR}'