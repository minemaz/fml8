#!/bin/sh
#
# $FML: list_up.sh,v 1.1.1.1 2001/02/11 13:27:44 fukachan Exp $
#

tmp=/tmp/$$
pwd=`pwd`

trap "rm -f $tmp" 0 1 3 15

cd ../.. || exit 1;

/usr/local/libexec/fml/fmlticket \
		--params pwd=$PWD \
		-c $pwd/main.cf \
		-R open \
		list /var/spool/ml/elena

exit 0;
