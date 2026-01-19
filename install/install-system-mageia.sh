#!/bin/bash

set -e
set -u
set -o pipefail
# Script to customize a Mageia distribution so it's ready for a Mageia Infra

# This first part is distribution specific and should be adapted based on its nature

PKGLIST="perl ansible openssh-server git python3-rpm jq"

# Base packages required
urpmi --auto $PKGLIST
