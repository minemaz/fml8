## Process this file with automake to create Makefile.in

## Copyright 2001, 2002 Free Software Foundation, Inc.
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2, or (at your option)
## any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; if not, write to the Free Software
## Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
## 02111-1307, USA.

m4sugarlibdir = $(pkgdatadir)/m4sugar
dist_m4sugarlib_DATA = m4sugar.m4 m4sh.m4
nodist_m4sugarlib_DATA = version.m4 m4sugar.m4f m4sh.m4f
CLEANFILES = $(nodist_m4sugarlib_DATA)

## ------------ ##
## version.m4.  ##
## ------------ ##

version.m4: $(top_srcdir)/configure.ac
	{					\
	  echo '# This file is part of -*- Autoconf -*-.'; \
	  echo '# Version of Autoconf.'; \
	  echo '# Copyright (C) 1999, 2000, 2001, 2002'; \
	  echo '# Free Software Foundation, Inc.'; \
	  echo ;\
	  echo 'm4_define([m4_PACKAGE_NAME],      [@PACKAGE_NAME@])'; \
	  echo 'm4_define([m4_PACKAGE_TARNAME],   [@PACKAGE_TARNAME@])'; \
	  echo 'm4_define([m4_PACKAGE_VERSION],   [@PACKAGE_VERSION@])'; \
	  echo 'm4_define([m4_PACKAGE_STRING],    [@PACKAGE_STRING@])'; \
	  echo 'm4_define([m4_PACKAGE_BUGREPORT], [@PACKAGE_BUGREPORT@])'; \
	} >version.m4


## --------------- ##
## Building TAGS.  ##
## --------------- ##

TAGS_FILES = $(dist_m4sugarlib_DATA)

ETAGS_ARGS = --lang=none \
  --regex='/\(A[CU]_DEFUN\|m4_\(defun\|define\)\|define\)(\[\([^]]*\)\]/\3/'


## -------- ##
## Checks.  ##
## -------- ##

check-local:
	if (cd $(srcdir) && \
	    grep '^_*EOF' $(dist_m4sugarlib_DATA)) >eof.log; then \
	  echo "ERROR: user EOF tags were used:" >&2; \
	  sed "s,^,$*.m4: ," <eof.log >&2; \
	  echo >&2; \
	  exit 1; \
	else \
	  rm -f eof.log; \
	fi


## ------------------ ##
## The frozen files.  ##
## ------------------ ##

m4sugar.m4f: $(m4sugar_m4f_dependencies)
m4sh.m4f: $(m4sh_m4f_dependencies)
include ../freeze.mk
