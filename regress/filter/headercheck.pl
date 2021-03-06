#!/usr/bin/env perl
#
# $FML: headercheck.pl,v 1.1 2001/09/22 15:24:03 fukachan Exp $
#

use lib qw(../../fml/lib ../../cpan/lib ../../img/lib);
use FileHandle;
use Mail::Message;

for my $f (@ARGV) {
    my $fh      = new FileHandle $f;
    my $message = Mail::Message->parse( { fd => $fh } );

    if (defined $message) {
	print STDERR "$f\t header = ";

	use FML::Filter::HeaderCheck;
	my $obj = new FML::Filter::HeaderCheck;

	$obj->header_check($message);
	if ($obj->error()) {
	    my $x = $obj->error();
	    $x =~ s/\s*at .*$//;
	    print STDERR "error: $x";
	}
	else {
	    print STDERR "ok\n";
	}
   }
}

exit 0;


sub _print
{
    my (@args) = @_;
    printf STDERR "%30s %s %s %s\n", @args;
}
