#!/bin/bash

set -e
set -u
set -o pipefail

usage() {
    echo "install.sh [-h][-n node][-i ip][-f fqdn][-g groupname][-u user][-k]"
    echo " "
    echo "where:"
    echo "node      is the type of node to deploy"
    echo "          valid values: build|repo|web|dploy"
    echo "          if empty using 'build'                "
    echo "groupname is the ansible group_vars name to be used"
    echo "          example: production, staging, test, ...  "
    echo "          if empty using 'production'                "
    echo "ip        IP address of the server being deployed"
    echo "          if empty, try to be autodetected from FQDN"
    echo "          Used in particuler when the IP can't be guessed such as with Vagrant"
    echo "fqdn      FQDN name of the server being deployed"
    echo "          example: build.mganet"
    echo "user      is the name of the admin user for autoinstall"
    echo "          example: mymgaadmin "
    echo "          if empty using mgaadmin               "
    echo "-k        is used, force the re-creation of ssh keys for the previously created admin user"
    echo "          if not used keep the existing keys in place if any (backed up and restored)"
    echo "          if the name of the admin user is changed, new keys are created"
}

echo "install.sh called with $*"
# Run as root
n=""
f=""
g=""
u=""
k=""
i=""
MGAGENKEYS=0
MGANET="mga.local"

while getopts "n:f:i:u:g:hk" option; do
    case "${option}" in
        n)
            n=${OPTARG}
            if [ ${n} !=  "build" ] && [ ${n} != "repo" ] && [ ${n} != "dploy" ] && [ ${n} != "web" ]; then
                echo "wrong type: ${n}"
                usage
                exit -1
            fi
            ;;
        f)
            f=${OPTARG}
            ;;
        i)
            i=${OPTARG}
            ;;
        g)
            g=${OPTARG}
            ;;
        u)
            u=${OPTARG}
            ;;
        k)
            MGAGENKEYS=1
            ;;
        h)
            usage
            exit 0
            ;;
        *)
            usage
            exit -1
            ;;
    esac
done
shift $((OPTIND-1))

if [ ! -z "${n}" ]; then
    MGATYPE="${n}"
else
    MGATYPE="build"
fi

if [ ! -z "${f}" ]; then
    MGAINSFQDN="`echo ${f} | cut -d: -f1`"
else
    MGAINSFQDN="$MGATYPE.$MGANET"
fi

if [ ! -z "${i}" ]; then
    MGAINSIP="${i}"
else
    set +e
    MGAINSIP=`ping -c 1 $MGAINSFQDN 2>/dev/null | grep PING | grep $MGAINSFQDN | cut -d'(' -f2 | cut -d')' -f1`
    set -e
    if [ _"$MGAINSIP" = _"" ]; then
        echo "Unable to find IP address for server $MGAINSFQDN"
        exit -1
    fi
fi

if [ ! -z "${u}" ]; then
    export MGAUSER="${u}"
else
    export MGAUSER="mgaadmin"
fi

if [ ! -z "${g}" ]; then
    MGAGROUP="${g}"
else
    MGAGROUP="production"
fi
export MGAGROUP MGAINSFQDN MGATYPE MGAINSIP

export MGADISTRIB=`grep -E '^ID=' /etc/os-release | cut -d= -f2 | sed 's/"//g'`-`grep -E '^VERSION_ID=' /etc/os-release | cut -d= -f2 | sed 's/"//g'`

echo "Installing a Mageia Infra $MGATYPE environment"
echo "Using groupname $MGAGROUP"
echo "Using admin user $MGAUSER"

SUDOUSR=${SUDO_USER:-}
# Needs to be root
if [ _"$SUDOUSR" = _"" ]; then
    echo "You need to use sudo to launch this script"
    exit -1
fi

HDIR=`grep -E "^$SUDO_USER" /etc/passwd | cut -d: -f6`
if [ _"$HDIR" = _"" ]; then
    echo "$SUDO_USER has no home directory"
    exit -1
fi

# redirect stdout/stderr to a file in the launching user directory
mkdir -p $HDIR/.mgainstall
exec &> >(tee $HDIR/.mgainstall/install.log)

echo "Install starting at `date`"
# Get path of execution
EXEPATH=`dirname "$0"`
export EXEPATH=`( cd "$EXEPATH" && pwd )`

source $EXEPATH/install.repo
# Overload MGAINSREPO if using a private one
if [ -f $EXEPATH/install.priv ]; then
    source $EXEPATH/install.priv
fi
export MGAINSREPO MGAINSBRANCH
echo "Installation environment :"
echo "---------------------------"
env | grep MGA
echo "---------------------------"

export MGATMPDIR=/tmp/mga.$$

# Create the MGAUSER user
if grep -qE "^$MGAUSER:" /etc/passwd; then
    MGAHDIR=`grep -E "^$MGAUSER" /etc/passwd | cut -d: -f6`
    if ps auxww | grep -qE "^$MGAUSER:"; then
       pkill -u $MGAUSER
       sleep 1
       set +e
       pkill -9 -u $MGAUSER
       set -e
    fi
    echo "$MGAUSER home directory: $MGAHDIR"
    if [ -d "$MGAHDIR/.ssh" ]; then
        echo "Original SSH keys"
        ls -al $MGAHDIR/.ssh/
        mkdir -p $MGATMPDIR
        chmod 700 $MGATMPDIR
        if [ $MGAGENKEYS -eq 0 ] && [ -f $MGAHDIR/.ssh/id_rsa ]; then
            echo "Copying existing SSH keys for $MGAUSER in $MGATMPDIR"
            cp -a $MGAHDIR/.ssh/[a-z]* $MGATMPDIR
        fi
        chown -R $MGAUSER $MGATMPDIR
    fi
    userdel -f -r $MGAUSER
    if [ -d $MGAHDIR ] && [ _"$MGAHDIR" != _"/" ]; then
        echo $MGAHDIR | grep -qE '^/home'
        if [ $? -eq 0 ]; then
            rm -rf $MGAHDIR
        fi
    fi

    # If we do not have to regenerate keys
    if [ $MGAGENKEYS -eq 0 ] && [ -d $MGATMPDIR ]; then
        echo "Preserved SSH keys"
        ls -al $MGATMPDIR
    else
        echo "Generating ssh keys for pre-existing $MGAUSER"
    fi
else
    echo "Generating ssh keys for non-pre-existing $MGAUSER"
fi
useradd -U -m -s /bin/bash $MGAUSER

# Manage passwd
export MGAPWD=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1`
echo "$MGAUSER:$MGAPWD" | chpasswd
echo "$MGAUSER is $MGAPWD" > $HDIR/.mgainstall/$MGAUSER

# setup sudo for $MGAUSER
cat > /etc/sudoers.d/$MGAUSER << EOF
Defaults:$MGAUSER !fqdn
Defaults:$MGAUSER !requiretty
$MGAUSER ALL=(ALL) NOPASSWD: ALL
EOF
chmod 440 /etc/sudoers.d/$MGAUSER

export MGAGENKEYS

# Call the distribution specific install script
echo "Installing $MGADISTRIB specificities for $MGATYPE"
$EXEPATH/install-system-$MGADISTRIB.sh

# In order to be able to access install script we need correct rights on the home dir of the uid launching the script
export MGAHDIR=`grep -E "^$MGAUSER" /etc/passwd | cut -d: -f6`
BKPSTAT=`stat --printf '%a' $MGAHDIR`
echo "Found $MGAUSER home directory $MGAHDIR with rights $BKPSTAT"
echo "Forcing temporarily open rights to access install scripts"
chmod o+x $MGAHDIR

HDIRSTAT=`stat --printf '%a' $HDIR`
echo "Found $SUDO_USER home directory $HDIR with rights $HDIRSTAT"
echo "Forcing temporarily open rights to access install scripts"
chmod o+x $HDIR

# Now drop priviledges
# Call the common install script to finish install
echo "Installing common remaining stuff as $MGAUSER"
su - $MGAUSER -w MGAGROUP,MGAINSFQDN,MGATYPE,MGAINSIP,MGADISTRIB,MGAUSER,MGAINSREPO,MGAINSBRANCH,MGAGENKEYS,MGATMPDIR,MGAHDIR -c "$EXEPATH/install-system-common.sh"

echo "Setting up original rights for $MGAHDIR with $BKPSTAT"
chmod $BKPSTAT $MGAHDIR

echo "Setting up original rights for $HDIR with $HDIRSTAT"
chmod $HDIRSTAT $HDIR

# In any case remove the temp dir
rm -rf $MGATMPDIR

echo "Install ending at `date`"
