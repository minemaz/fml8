#!/bin/sh
#
# $Id$
#

cd .. || exit 1
pwd
cat regress/example.re |\
perl -w fml/libexec/fmlwrapper \
	--params pwd=$PWD \
	-c $PWD/regress/main.cf \
	/var/spool/ml/elena

echo "-- exit code: $?"

exit 0
