#!/bin/bash

#set -x
set -e
set -u
set -o pipefail

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

MGASCRIPTDIR="$MGAREPODIR/scripts"
MGAPBKDIR=$MGAGROUP
MGAANSIBLEDIR=$MGAREPODIR/ansible
# This is where mageia.sh will be stored
MGALOCAL=`ansible-inventory -i $MGAANSIBLEDIR/inventory --host $MGAGROUP --playbook-dir $MGAANSIBLEDIR | jq ".MGALOCAL" | sed 's/"//g'`
# We need to be able to create files there
sudo chown $MGAUSER $MGALOCAL/{etc,bin}

# Declares shell variables as ansible variables as well
# then they can be used in playbooks
cat > $MGALOCAL/bin/mageia.sh << EOF
# This is the mageia.sh script, generated at install
#
# Name of the admin user
export MGAUSER=$MGAUSER

# Name of the mageia machine type (build, web, dploy, repo, ...)
export MGATYPE=$MGATYPE

# Location of the autoinstall directory
export MGAINSDIR=$MGAINSDIR

# Shell variables for Mageia
#
# AUTOINSTALL PART
# The autosinstall dir has some fixed subdirs 
# autoinstall-mageia (MGAREPODIR)
#    |---------- ansible (MGAANSIBLEDIR)
#    |---------- scripts (MGASCRIPTDIR)
#    |---------- sys (MGASYSDIR)
#    |---------- install (MGAINSDIR)
#    |---------- conf
#    |---------- skel
#
export MGAANSIBLEDIR=$MGAANSIBLEDIR
export MGASYSDIR=$MGAREPODIR/sys
export MGAPBKDIR=$MGAPBKDIR

export MGALOCAL=$MGALOCAL
EOF

chmod 755 $MGALOCAL/bin/mageia.sh
source $MGALOCAL/bin/mageia.sh

export MGAANSPLAYOPT="-e MGAANSIBLEDIR=$MGAANSIBLEDIR -e LDAPSETUP=0"
cat >> $MGALOCAL/bin/mageia.sh << EOF
export MGAANSPLAYOPT="$MGAANSPLAYOPT"
EOF

cd $MGAANSIBLEDIR
# Prepare variables for ansible
cat > $MGALOCAL/etc/mageia.yml << EOF
MGAUSER: $MGAUSER
MGAANSIBLEDIR: $MGAANSIBLEDIR
MGAREPODIR: $MGAREPODIR
MGASYSDIR: $MGASYSDIR
MGATYPE: $MGATYPE
MGAPBKDIR: $MGAPBKDIR
MGAINSDIR: $MGAINSDIR
MGASCRIPTDIR: $MGASCRIPTDIR
MGAINSBRANCH: $MGAINSBRANCH
MGAINSREPO: $MGAINSREPO
MGAHDIR: $MGAHDIR
EOF

if ! command -v ansible-galaxy &> /dev/null
then
    echo "ansible-galaxy could not be found, please install ansible"
    exit -1
fi

# Install ansible collections needed
if [ $MGADISTRIB = "mageia-9" ]; then
    # Older distributions require an older version of the collection to work.
    # See https://github.com/ansible-collections/community.general
    ansible-galaxy collection install --force-with-deps community.general:4.8.5
else
    ansible-galaxy collection install community.general
fi
ansible-galaxy collection install ansible.posix

# Automatic Installation script for the system 
CMD="ansible-playbook -i inventory --limit $MGAPBKDIR $MGAANSPLAYOPT install_$MGATYPE.yml"
echo "Executing $CMD"
$CMD
if [ $? -ne 0 ]; then
	echo "Install had errors exiting before launching check"
	exit -1
fi

# Create a conformity check script and runs it
cat > $MGALOCAL/bin/mageia-srv-check << EOF
#!/bin/bash
#
# Get needed variables build at install
source $MGALOCAL/bin/mageia.sh
if [ -f $MGALOCAL/autoinstall/mageia.sh ]; then
	source $MGALOCAL/autoinstall/mageia.sh
fi
EOF

cat >> $MGALOCAL/bin/mageia-srv-check << 'EOF'
cd $MGAANSIBLEDIR
CMD="ansible-playbook -i inventory --limit $MGAPBKDIR $MGAANSPLAYOPT check_$MGATYPE.yml"
echo "Executing $CMD"
$CMD
EOF

chmod 755 $MGALOCAL/bin/mageia-srv-check
$MGALOCAL/bin/mageia-srv-check

date
