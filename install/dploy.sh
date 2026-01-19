#!/bin/bash

usage() {
    echo "dploy.sh [-h][-n node][-f fqdn]"
    echo " "
    echo "where:"
    echo "node      is the type of node to deploy"
    echo "          valid values: build|repo|web|dploy"
    echo "          if empty using 'build'                "
    echo "fqdn      FQDN name of the server being deployed"
}

f=""
n=""
while getopts "n:f:h" option; do
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
	MGAINSFQDN="${f}"
else
	usage
	exit -2
fi

# redirect stdout/stderr to a file in the launching user directory
mkdir -p $HDIR/.mgainstall
exec &> >(tee $HDIR/.mgainstall/dploy.log)

echo "dploy starting at `date`"
# Get path of execution
EXEPATH=`dirname "$0"`
export EXEPATH=`( cd "$EXEPATH" && pwd )`

source $EXEPATH/install.repo
# Overload MGAINSREPO if using a private one
if [ -f $EXEPATH/install.priv ]; then
    source $EXEPATH/install.priv
fi

ssh fwadmin@$MGAINSFQDN "rm -rf autoinstall-mageia ; git clone $MGAINSREPO ; cd autoinstall-mageia ; git checkout $MGAINSBRANCH ; cd install ; sudo ./install.sh -n $MGATYPE -g production -f ${f}"
