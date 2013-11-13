sdf-mon
=======

Scripts to provide rudimentary heartbeat and health monitor of Debian servers.

## Setup Process

### SSH User

The check.sh script makes use of SSH to facilitate connecting to the remote 
host. For information on what SSH is or how it works, read 
[this](https://en.wikipedia.org/wiki/Secure_Shell). The Reader's Digest 
summation of SSH is that it's a client/server utility that allows you to start 
a remote command line session on a remote (or local) machine over an encrypted 
connection. It offers lots of really awesome functionality and I do encourage 
you to follow [that link](https://en.wikipedia.org/wiki/Secure_Shell) to learn 
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
['pw'](http://www.freebsd.org/cgi/man.gi?query=pw&apropos=0&sektion=8&manpath=Fr
eeBSD+9.2-RELEASE&arch=default&format=html), so read through the links if that 
fits your needs.

Now that simon exists, we can generate an SSH key pair and add them to simon's 
authorized_keys file. Logged into the host that will run the check.sh script as 
the user that will execute the script, run the following command:

`ssh-keygen -b 2048 -C 'check.sh ssh key'`

You will be prompted for a few options, accepting the defaults by pressing 
'Enter/Return' it will generate an SSH key pair with a 2048 bit key length and 
a comment that will help you identify the keys. It writes these out to 
`~/.ssh/id_rsa` and `~/.ssh/id_rsa.pub`. The important things to know about SSH 
keys is that the 'id_rsa' key is your private key and should be kept safe, it 
should never leave the host computer unless you specifically intend it to, 
'id_rsa.pub' is the public key that is distributed to the hosts that you wish to
remotely access via SSH. 



### Config File



### cron


## Usage


## Implementation details

### mailx
