#
# $FML: Makefile,v 1.17 2001/07/01 14:07:40 fukachan Exp $
#

CONV = doc/bin/text2html.pl

all: usage

usage:
	@ echo "make install    install"
	@ echo ""
	@ echo "make doc        generate documents"
	@ echo "make tutorial   generate turorials"
	@ echo ""
	@ echo "make clean             "

install:
	sh INSTALL.sh

scan:
	@ cvs -n update 2>&1 |grep -v : || echo ''

update:
	@ cvs update -d -P|grep -v : || echo ''

clean:
	@ find . |grep '~' |perl -nple unlink

doc: html

html: _new_doc _html ja.doc

_new_doc:
	test -d Documentation/en/modules || mkdir Documentation/en/modules
	-fml/utils/bin/pm2txt.pl fml/lib  Documentation/en/modules
	-fml/utils/bin/pm2txt.pl cpan/lib Documentation/en/modules
	-fml/utils/bin/pm2txt.pl img/lib  Documentation/en/modules

_html:
	@ (cd fml/libexec/; make html)
	@ (cd fml/etc/;     make html)
	@ (cd cpan/dist/;   make html)
	@ (cd img/dist/;    make html)

ja.doc:
	@ (cd fml/doc/ja/; make clean; make ; make clean)
