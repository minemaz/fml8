#!/bin/sh
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

# Run this from the top-level fml source directory.

PATH=/bin:/usr/bin:/usr/sbin:/usr/etc:/sbin:/etc
umask 022

### configurations ###
default_prefix=/usr/local
config_dir=/etc/fml
libexec_dir=$default_prefix/libexec/fml
lib_dir=$default_prefix/lib/fml


# ml spool
ml_spool_dir=/var/spool/ml

# owner of /var/spool/ml
owner=fml

######################

get_fml_version () {
   if [ -f .version ];then
	fml_version=`cat .version`
   else
	date=`date +%C%y%m%d`
	fml_version=current-${date}
   fi
}

_mkdir () {
	local dir=$1 
	echo mkdir $dir; 
	test -d $dir || mkdir -p $dir
}


get_fml_version

for dir in 	$config_dir \
		$config_dir/defaults \
		$config_dir/defaults/$fml_version \
		$lib_dir	\
		$lib_dir/$fml_version	\
		$libexec_dir	\
		$libexec_dir/$fml_version \
		$ml_spool_dir
do
   test -d $dir || _mkdir $dir
done


if [ ! -f $config_dir/main.cf ];then
	echo create $config_dir/main.cf
	sed 	-e s@__fml_version__@$fml_version@ \
		-e s@__config_dir__@$config_dir@ \
		-e s@__default_prefix__@$default_prefix@ \
		fml/etc/main.cf > $config_dir/main.cf
fi

echo update $config_dir/defaults/$fml_version/
cp fml/etc/default_config.cf.ja $config_dir/defaults/$fml_version/default_config.cf

echo update $lib_dir/$fml_version/
cp -pr fml/lib/*	$lib_dir/$fml_version/
cp -pr cpan/lib/*	$lib_dir/$fml_version/

echo update $libexec_dir/$fml_version/
cp -pr fml/libexec/*	$libexec_dir/$fml_version/

PROGRAMS="fml.pl distribute command ";
PROGRAMS="$PROGRAMS fmlserv mead fmlconf fmldoc"
PROGRAMS="$PROGRAMS fmlticket fmlticket.cgi"

if [ ! -f $libexec_dir/loader ];then

   echo install libexec/loader
   cp -pr fml/libexec/loader    $libexec_dir/

   echo install libexec/Standalone.pm
   cp -pr fml/libexec/Standalone.pm $libexec_dir/

   (
	cd $libexec_dir/

	echo -n "   link loader to: "
	for x in $PROGRAMS
	do
		rm -f $x
		ln -s loader $x && echo -n "$x "
	done
	echo ""
   )
fi

iam=`id -un`

if [ "X$iam" != Xroot ];then
	exit 1
fi

id -un $owner || exit 1

if [ -d $ml_spool_dir -a -w $ml_spool_dir ]; then
	echo set up the owner of $ml_spool_dir to be $owner
	chown -R $owner $ml_spool_dir
fi

exit 0
