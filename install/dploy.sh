#!/bin/bash

usage() {
    echo "dploy.sh [-h][-t type][-f fqdn]"
    echo " "
    echo "where:"
    echo "type      is the installation type"
    echo "          valid values: buildnode|reposerver|webserver"
    echo "          if empty using 'buildnode'                "
    echo "fqdn      FQDN name of the server being deployed"
}

f=""
t=""
while getopts "t:f:h" option; do
    case "${option}" in
        t)
            t=${OPTARG}
            if [ ${t} !=  "buildnode" ] && [ ${t} != "reposerver" ] && [ ${t} != "webserver" ]; then
                echo "wrong type: ${t}"
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

if [ ! -z "${t}" ]; then
    MGATYPE="${t}"
else
    MGATYPE="buildnode"
fi
if [ ! -z "${f}" ]; then
	MGAINSFQDN="${f}"
else
	usage
	exit -2
fi
ssh fwadmin@$MGAINSFQDN "rm -rf autoinstall-mageia ; git clone https://github.com/bcornec/autoinstall-mageia.git ; cd autoinstall-mageia/install ; sudo ./install.sh -t $MGATYPE -g production -f ${f}"

