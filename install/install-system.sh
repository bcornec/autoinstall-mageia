#!/bin/bash

#set -x

date

export MGATYPE=$1
if [ -z "$MGATYPE" ]; then
	echo "Syntax: install-system.sh build|web|repo|dploy"
	exit -1
fi

if [ ! -f $HOME/.gitconfig ]; then
	cat > $HOME/.gitconfig << EOF
# This is Git's per-user configuration file.
[user]
# Please adapt and uncomment the following lines:
name = $MGAUSER
email = $MGAUSER@mageia.org
EOF
fi

# This is where mga.sh will be stored
MGASCRIPTDIR="$MGAREPODIR/scripts"

cat > $MGASCRIPTDIR/mga.sh << EOF
# This is the mga.sh script, generated at install
#
# Name of the admin user
export MGAUSER=$MGAUSER

# Name of the mga machine type (build, web, dploy, repo, ...)
export MGATYPE=$MGATYPE

# Location of the autoinstall directory
export MGAINSDIR=$MGAINSDIR

EOF
cat >> $MGASCRIPTDIR/mga.sh << 'EOF'
# Shell variables for Mageia
#
# AUTOINSTALL PART
# The autosinstall dir has some fixed subdirs 
# autoinstall-mageia (MGAREPODIR)
#    |---------- ansible (MGAANSIBLEDIR)
#    |---------- scripts (MGASCRIPTDIR defined in all.yml not here to allow overloading)
#    |---------- sys (MGASYSDIR)
#    |---------- install (MGAINSDIR)
#    |---------- conf
#    |---------- skel
#
export MGAANSIBLEDIR=$MGAREPODIR/ansible
export MGASYSDIR=$MGAREPODIR/sys

EOF

chmod 755 $MGASCRIPTDIR/mga.sh
source $MGASCRIPTDIR/mga.sh

cd $MGAANSIBLEDIR
# Prepare variables for ansible
cat > $MGAANSIBLEDIR/mga.yml << EOF
MGAUSER: $MGAUSER
MGAANSIBLEDIR: $MGAANSIBLEDIR
MGAREPODIR: $MGAREPODIR
MGASYSDIR: $MGASYSDIR
MGATYPE: $MGATYPE
MGAPBKDIR: $MGAPBKDIR
MGAINSDIR: $MGAINSDIR
MGASCRIPTDIR: $MGASCRIPTDIR
EOF

MGAPBKDIR=$MGAGROUP

# Declares shell variables as ansible variables as well
# then they can be used in playbooks
MGAANSPLAYOPT="-e MGAANSIBLEDIR=$MGAANSIBLEDIR"

# For future mga.sh usage by other scripts
cat >> $MGASCRIPTDIR/mga.sh << EOF
export MGAANSPLAYOPT="$MGAANSPLAYOPT"
export MGAPBKDIR=$MGAPBKDIR
EOF
export MGAANSPLAYOPT

if ! command -v ansible-galaxy &> /dev/null
then
    echo "ansible-galaxy could not be found, please install ansible"
    exit -1
fi

# Install ansible collections needed
ansible-galaxy collection install community.general
ansible-galaxy collection install ansible.posix

MGAANSPLAYOPT="$MGAANSPLAYOPT -e LDAPSETUP=0"

# Automatic Installation script for the system 
ansible-playbook -i inventory --limit $MGAPBKDIR $MGAANSPLAYOPT install_$MGATYPE.yml
if [ $? -ne 0 ]; then
	echo "Install had errors exiting before launching startup"
	exit -1
fi

cd $MGAANSIBLEDIR
ansible-playbook -i inventory --limit $MGAPBKDIR $MGAANSPLAYOPT check_$MGATYPE.yml
date
