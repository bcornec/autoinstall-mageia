#!/bin/bash
#
# Get asset tag from iLO
# and return it on stdout
#
sudo hponcfg -f {{ MGALOCAL }}/etc/get-ilo-asset-tag.xml | grep 'ASSET_TAG VALUE' | perl -p -e 's|<ASSET_TAG VALUE =. *(.*)./>|$1|'
