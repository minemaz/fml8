PERL = perl -w -I ./lib/fml5 -I ./lib/CPAN -I ./lib/3RDPARTY -I ./lib

all: test

scan:
	@ cvs -n update 2>&1 |grep -v : || echo ''

update:
	@ cvs update -dAP|grep -v : || echo ''

test: test2 

test1:
	@ cat w/example |\
	  perl -w libexec/distribute etc/default_config.cf etc/config.cf

test2:
	@ cat w/example |\
	  perl -w libexec/fml.pl /var/spool/ml/elena

test3:
	@ echo '-- test in the case where Socket6 fail'
	@ cat w/example |\
	  /usr/pkg/bin/perl -w libexec/fml.pl /var/spool/ml/elena

check:
	@ for x in `find lib* -type f -print|grep pm|grep -v CPAN` ; do $(PERL) -c $$x || echo '' ;done

clean:
	@ find . |grep '~' |perl -nple unlink

link:
	rm -f FML Netlib IO 
	ln -s lib/fml5/FML .
	ln -s lib/fml5/Netlib .
	ln -s lib/fml5/IO .
	(cd libexec; ln -s fmlwrapper fml.pl) 

hier:
	perl bin/show_hierarchy.pl FML/libkern.pl | uniq
