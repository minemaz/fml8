#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: DSN.pm,v 1.7 2001/07/30 14:42:34 fukachan Exp $
#


package Mail::Bounce::DSN;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

my $debug = $ENV{'debug'} ? 1 : 0;

@ISA = qw(Mail::Bounce);


=head1 NAME

Mail::Bounce::DSN - DSN error message format parser

=head1 SYNOPSIS

See C<Mail::Bounce> for more details.

=head1 DESCRIPTION

See C<Mail::Bounce> for more details.

=head1 ERROR EXAMPLE

   From: MAILER-DAEMON@ahodori.fml.org (Mail Delivery System)
   Subject: Undelivered Mail Returned to Sender
   To: fml-help-admin@ffs.fml.org
   MIME-Version: 1.0
   Content-Type: multipart/report; report-type=delivery-status;
   	boundary="C687D866E0.986737575/ahodori.fml.org"
   Message-Id: <20010408134615.F1DD786658@ahodori.fml.org>
   
   This is a MIME-encapsulated message.
   
   --C687D866E0.986737575/ahodori.fml.org
   Content-Description: Notification
   Content-Type: text/plain
   
   This is the Postfix program at host ahodori.fml.org.

       ... reason ...
   
   --C687D866E0.986737575/ahodori.fml.org
   Content-Description: Delivery error report
   Content-Type: message/delivery-status
   
   Reporting-MTA: dns; ahodori.fml.org
   Arrival-Date: Sun, 25 Mar 2001 22:34:15 +0900 (JST)
   
   Final-Recipient: rfc822; rudo@nuinui.net
   Action: failed
   Status: 4.0.0
   Diagnostic-Code: X-Postfix; connect to sv.nuinui.net[210.161.170.173]:
       Connection refused
   
   --C687D866E0.986737575/ahodori.fml.org
   Content-Description: Undelivered Message
   Content-Type: message/rfc822
   
       ... original message ...
   
   -- rudo's mabuachi
   
   --C687D866E0.986737575/ahodori.fml.org--

=cut


sub analyze
{
    my ($self, $msg, $result) = @_;
    my $m = $msg->rfc822_message_body_head;
    $m = $m->find( { data_type => 'message/delivery-status' } );

    if (defined $m) {
	# data in the part
	my $data = $m->data;
	my $n    = $m->num_paragraph;

	for (my $i = 0; $i < $n; $i++) {
	    my $buf = $m->nth_paragraph($i + 1); # 1 not 0 for 1st paragraph
	    if ($buf =~ /Recipient/) {
		$self->_parse_dsn_format($buf, $result);
	    }
	}
    }
    else {
	return undef;
    }

    $result;
}


# DSN Example:
#    Final-Recipient: rfc822; rudo@nuinui.net
#    Action: failed
#    Status: 4.0.0
#    Diagnostic-Code: X-Postfix; connect to mx.nuinui.net[10.1.1.1]:
#                     Connection refused
sub _parse_dsn_format
{
    my ($self, $buf, $result) = @_;

    use Mail::Header;
    my @h      = split(/\n/, $buf);
    my $header = new Mail::Header \@h;
    my $addr   = $header->get('Original-Recipient') || 
	$header->get('Final-Recipient');

    if ($addr =~ /.*;\s*(\S+\@\S+\w+)/) { $addr = $1;}
    $addr = $self->address_clean_up($self, $addr);

    # set up return buffer
    if ($addr =~ /\@/) {
	$result->{ $addr }->{ 'Final-Recipient' } = $addr;
	for ('Final-Recipient', 
	     'Original-Recipient',
	     'Action', 
	     'Status', 
	     'Diagnostic-Code',
	     'Reporting-MTA', 
	     'Received-From-MTA') {
	    $result->{ $addr }->{ $_ } = $header->get($_) || undef;
	}
	$result->{ $addr }->{ 'hints' } = 'DSN';
    }
}

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

Mail::Bounce::DSN appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
