#!/bin/bash

set -x 

date

export MGATYPE=$1
if [ -z "$MGATYPE" ]; then
	echo "Syntax: install-system.sh sucuk|ecosse|rabbit|duvel|fiona"
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

SCRIPT=`realpath $0`
# This is the installation directory where install scripts are located.
INSTALLDIR=`dirname $SCRIPT`

# This main dir is computed and is the backend main dir
export MGAINSDIR=`dirname $INSTALLDIR`

# This is where mga.sh will be stored
SCRIPTDIR="$MGAINSDIR/scripts"

cat > $SCRIPTDIR/mga.sh << EOF
# This is the mga.sh script, generated at install
#
# Name of the admin user
export MGAUSER=$MGAUSER

# Name of the mga machine type (sucuk|ecosse|rabbit|duvel|fiona)
export MGATYPE=$MGATYPE

# Location of the autoinstall directory
export MGAINSDIR=$MGAINSDIR

EOF
cat >> $SCRIPTDIR/mga.sh << 'EOF'
# AUTOINSTALL PART
# The auntosinstall dir has some fixed subdirs 
# autoinstall-mageia (MGAINSDIR)
#    |---------- ansible (ANSIBLEDIR)
#    |---------- scripts (SCRIPTDIR defined in all.yml not here to allow overloading)
#    |---------- sys (SYSDIR)
#    |---------- install
#    |---------- conf
#    |---------- skel
#
export ANSIBLEDIR=$MGAINSDIR/ansible
export SYSDIR=$MGAINSDIR/sys

EOF

chmod 755 $SCRIPTDIR/mga.sh
source $SCRIPTDIR/mga.sh

cd $SCRIPTDIR/../ansible
PBKDIR=$MGAGROUP

# Declares shell variables as ansible variables as well
# then they can be used in playbooks
ANSPLAYOPT="-e PBKDIR=$PBKDIR -e MGAUSER=$MGAUSER -e MGAINSDIR=$MGAINSDIR -e ANSIBLEDIR=$ANSIBLEDIR -e SCRIPTDIR=$SCRIPTDIR -e SYSDIR=$SYSDIR"

# For future mga.sh usage by other scripts
cat >> $SCRIPTDIR/mga.sh << EOF
export ANSPLAYOPT="$ANSPLAYOPT"
export PBKDIR=$PBKDIR
EOF
export ANSPLAYOPT

if ! command -v ansible-galaxy &> /dev/null
then
    echo "ansible-galaxy could not be found, please install ansible"
    exit -1
fi

# Install ansible collections needed
ansible-galaxy collection install community.general
ansible-galaxy collection install ansible.posix

# Automatic Installation script for the system 
ansible-playbook -i inventory --limit $PBKDIR $ANSPLAYOPT install_$MGATYPE.yml
if [ $? -ne 0 ]; then
	echo "Install had errors exiting before launching startup"
	exit -1
fi

cd $ANSIBLEDIR
ansible-playbook -i inventory --limit $PBKDIR $ANSPLAYOPT check_$MGATYPE.yml
date
