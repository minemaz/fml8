#!/usr/local/bin/perl
#
# $Id$
#


use strict;
use Carp;
use FML::MIME qw(decode_mime_string encode_mime_string);
use MIME::Base64;
use MIME::QuotedPrint;


&try_mime(" ");
&try_mime("　");
&try_mime("\n");

exit 0;


sub try_mime
{
    my ($separator) = @_;
    my $buf = "\n";

    my $orig_str = "うじゃ". $separator ."あじゃじゃ";
    my $in_str_b64 = encode_mime_string($orig_str);
    my $in_str_qp  = encode_mime_string($orig_str, { encode => 'qp' });

    $buf .=  ">". $orig_str. "<\n";
    $buf .=  ">". $in_str_b64. "<\n";
    $buf .=  ">". $in_str_qp. "<\n";

    my $out_str_b64 = 
	decode_mime_string($in_str_b64, {charset => 'euc-japan'});
    $buf .=  "<". $out_str_b64. "<\n";

    my $out_str_qp = decode_mime_string($in_str_qp, {charset => 'euc-japan'});
    $buf .=  "<". $out_str_qp. "<\n";

    $buf =~ s/\n/\n   |/g;
    print $buf, "\n";
    print ($orig_str eq $out_str_b64 ? "base64 ... ok\n" : "fail\n");
    print ($orig_str eq $out_str_qp  ? "qp     ... ok\n" : "fail\n");
}


1;
