#!/bin/sh
# Customize shell prompt
export PS1="\[\e[32;1m\]\u\[\e[m\]@\[\e[34;1m\]\H\[\e[m\]:\[\e[33;1m\]\w\[\e[m\]$ "
# Set default permission of new files to allow group access
umask u+rwx,g+rwx,o-rwx
# Activate conda base environment
. /opt/conda/etc/profile.d/conda.sh
conda activate
# verify not root
if ! [ $(id -u) = 0 ]; then
	# Default to the anaconda user
	ORIG_USER=anaconda
	# Detect if renaming user
	if [ -z "$NEW_USER" ]; then
		NEW_USER=$ORIG_USER
	fi
	# Detect if 'moving' home dir
	if [ -z "$NEW_HOME" ]; then
		NEW_HOME=$HOME
	fi
	# Fix UID/GID (for permissions), rename user, and rename home as appropriate
	CURR_DIR=$(pwd) # this is necessary to prevent collisions if standing in directory
	cd /tmp
	/startup -user=$ORIG_USER -new_uid=$(id -u) -new_gid=$(id -g) -new_user=${NEW_USER} -new_home=$NEW_HOME
	export HOME=/home/${NEW_USER}
	cd $CURR_DIR 2>/dev/null || cd $HOME
fi
export PATH=$(readlink -f "$HOME")/.local/bin:$PATH