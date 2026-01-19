#!/bin/bash

# Function to manage git cloning of the repo correctly
# Shared between multiple install scripts.
#

mga_clean_clone_log() {
BRANCH=$1
shift
# Now get the directory in which we cloned
REPODIR=`echo "$*" | tr ' ' '\n' | tail -1`
res=`echo $REPODIR | { grep "://" || true; }`
if [ _"$res" != _"" ]; then
	# REPODIR points to URL not dir
	# dir is then computed automatically
	MGAREPODIR="$MGAHDIR/`echo "$REPODIR" | tr '/' '\n' | tail -1 | sed 's/\.git$//'`"
else
	MGAREPODIR="$MGAHDIR/$REPODIR"
fi
export MGAREPODIR

if [ _"$MGAREPODIR" = _"" ]; then
	echo "Directory into which to clone is empty"
	exit -1
fi
if [ _"$MGAREPODIR" = _"/" ]; then
	echo "Directory into which to clone is /"
	exit -1
fi
if [ _"$MGAREPODIR" = _"$HOME" ]; then
	echo "Directory into which to clone is $HOME"
	exit -1
fi
echo "Using repo directory $MGAREPODIR"

# Remove directory first
rm -rf $MGAREPODIR

# This line will clone the repo
git clone $*

# This line checks the correct branch out
# And store commit Ids for these repos
(cd $MGAREPODIR ; git checkout $BRANCH ; echo "$MGAREPODIR: `git show --oneline | head -1 | awk '{print $1}'`")
}

