#!/bin/bash

# This is the second part of the installation process that is called by a specific installation script for a distribution
# Run as root

set -e
set -u
set -o pipefail

source $EXEPATH/install-functions.sh

# This is run as MGAUSER user
rm -rf .ssh

mga_clean_clone_log $MGAINSBRANCH $MGAINSREPO

# This is the installation directory where install scripts are located.
export MGAINSDIR="$MGAREPODIR/install"

if [ $MGAGENKEYS -eq 0 ] && [ -f "$MGATMPDIR/id_rsa" ]; then
	# We do not have to regenerate keys and reuse existing one preserved
	echo "Keep existing ssh keys for $MGAUSER"
	ls -al $MGATMPDIR
	mkdir -p .ssh
	chmod 700 .ssh
	cp $MGATMPDIR/[a-z]* .ssh
	chmod 644 .ssh/*
	chmod 600 .ssh/id_rsa
	if [ -f .ssh/authorized_keys ]; then
		chmod 600 .ssh/authorized_keys
	fi
else
	# Setup ssh for MGAUSER
	echo "Generating ssh keys for $MGAUSER"
	ssh-keygen -t rsa -b 4096 -N '' -f $HOME/.ssh/id_rsa
	install -m 0600 $MGAREPODIR/skel/.ssh/authorized_keys .ssh/
	cat $HOME/.ssh/id_rsa.pub >> $HOME/.ssh/authorized_keys
fi
# temp dir remove in caller by root to avoid issues

# Setup this using the group for Mageia
cat > $MGAREPODIR/ansible/group_vars/$MGAGROUP << EOF
PBKDIR: $MGAGROUP
# 
# Installation specific values
# Modify afterwards or re-run the installer to update
#
MGAINSFQDN: $MGAINSFQDN
MGAINSIP: $MGAINSIP
MGADISTRIB: $MGADISTRIB
MGAINSDIR: $MGAINSDIR
MGAREPODIR: $MGAREPODIR
EOF
cat $MGAREPODIR/ansible/group_vars/mageia-system >> $MGAREPODIR/ansible/group_vars/$MGAGROUP

if [ -f $MGAREPODIR/ansible/group_vars/mageia-$MGATYPE ]; then
	cat $MGAREPODIR/ansible/group_vars/mageia-$MGATYPE >> $MGAREPODIR/ansible/group_vars/$MGAGROUP
fi

# Inventory based on the installed system
cat > $MGAREPODIR/ansible/inventory << EOF
[$MGAGROUP]
$MGAINSFQDN ansible_connection=local
EOF

# Change default passwd for vagrant and root

# Install Mageia infra server
$MGAINSDIR/install-system.sh $MGATYPE
