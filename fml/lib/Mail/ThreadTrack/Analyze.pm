#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: @template.pm,v 1.1 2001/08/07 12:23:48 fukachan Exp $
#

package Mail::ThreadTrack::Analyze;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

Mail::ThreadTrack::Analyze - analyze mail thread relation

=head1 SYNOPSIS

    my $ticket = $pkg->new($args);
    if (defined $ticket) {
	$ticket->analyze($msg);
	$ticket->rewrite_header($msg);
    }

=head1 DESCRIPTION

=head1 METHODS

=cut


=head2 C<analyze($mesg)>

C<$mesg> is Mail::Message object.

1) assign a new ticket or extract the existing ticket-id from the subject.

2) update ticket status if needed.

=cut


sub analyze
{
    my ($self, $msg) = @_;
    $self->_assign($msg);
    $self->update_ticket_status($msg);
    $self->update_db($msg);
}


=head2 assign($msg)

=cut


sub _is_reply
{
    my ($subject) = @_;

    use Mail::Message::Language::Japanese::Subject;
    return Mail::Message::Language::Japanese::Subject::is_reply($subject);
}


# Descriptions: assign a new ticket or 
#               extract the existing ticket-id from the subject
#    Arguments: $self $curproc $args
# Side Effects: a new ticket_id may be assigned
#               article header is rewritten
# Return Value: none
sub _assign
{
    my ($self, $msg) = @_;
    my $config   = $self->{ _config };
    my $header   = $msg->rfc822_message_header();
    my $subject  = $header->get('subject');
    my $pcb      = $self->{ _pcb };
    my $is_reply = _is_reply($subject);

    # 1. try to extract $ticket_id from subject: field
    my $ticket_id = $self->_extract_ticket_id_in_subject($header, $config);
    unless ($ticket_id) {
	# 1.1 hmm, we tail to but we try to speculate ticket_id 
	#     from other header information.
	$ticket_id = $self->_speculate_ticket_id($msg);
	if ($ticket_id) {
	    $is_reply = 1;
	    $self->{ _ticket_id } = $ticket_id;
	    Log("speculated id=$ticket_id");
	}
	else {
	    Log("(debug) fail to spelucate ticket_id");
	}
    }

    # 2. check "X-Ticket-Pragma:" field, 
    #    we ignore this mail if the pragma is specified as "ignore".
    if (defined $header->get('x-ticket-pragma')) {
	my $pragma = $header->get('x-ticket-pragma') || '';
	if ($pragma =~ /ignore/i) {
	    $self->{ _pragma } = 'ignore';
	    $self->_append_ticket_status_info("ignored");
	    return undef;
	}
    }
    
    # if the header carries "Subject: Re: ..." with ticket-id, 
    # we do not rewrite the subject but save the extracted $ticket_id.
    if ($is_reply && $ticket_id) {
	Log("reply message with ticket_id=$ticket_id");
	$self->{ _ticket_id } = $ticket_id;
	$self->{ _status    } = 'analyzed';
	$self->_append_ticket_status_info('analyzed');
    }
    elsif ($ticket_id) {
	Log("usual message with ticket_id=$ticket_id");
	$self->{ _ticket_id } = $ticket_id;
	$self->_append_ticket_status_info("found");
    }
    else {
	Log("message with no ticket_id");

	# assign a new ticket number for a new message
	my $id = $self->increment_id();

	# O.K. rewrite Subject: of the article to distribute
	unless ($self->error) {
	    $pcb->{'article'}->{'id'} = $id; # save $id info in PCB

	    my $header = $msg->rfc822_message_header();
	    $self->_get_ticket_id($header, $config, $id);
	    $self->_rewrite_header($header, $config, $id);
	    $self->_append_ticket_status_info("newly assigned");
	}
	else {
	    Log( $self->error );
	}
    }
}


# For example, consider a posting to both elena ML and rudo (DM) from kenken.
#
#     From: kenken 
#     To: elena-ml
#     Cc: rudo
#
# The reply to this DM (direct message) from rudo is
#
#     From: rudo
#     To: elena-ml
#
# This reply message has no ticket_id since the message from kenken to
# rudo comes directly from kenken not through fml driver.
# In this case, we try to speculdate the reply relation and the ticket_id
# of this thread by using _speculate_ticket_id().
#
sub _speculate_ticket_id
{
    my ($self, $msg) = @_;
    my $header  = $msg->rfc822_message_header();
    my $midlist = _extract_message_id_references( $header );
    my $result  = '';

    for (@$midlist) { Log("(debug) mid=$_");}

    if (defined $midlist) {
	$self->db_open();

	# prepare hash table tied to db_dir/*db's
	my $rh = $self->{ _hash_table };

	for my $mid (@$midlist) { 
	    $result = $rh->{ _message_id }->{ $mid };
	    last if $result;
	}

	$self->db_close();
    }

    Log("(debug) not speculated") unless $result;
    $result;
}


sub _append_ticket_status_info
{
    my ($self, $s) = @_;
    $self->{ _status_info } .= $self->{ _status_info } ? " -> ".$s : $s;
}


=head2 update_ticket_status($msg)

=cut


sub update_ticket_status
{
    my ($self, $msg) = @_;

    return if $self->{ _pragma } eq 'ignore';

    # entries to check
    my $header  = $msg->rfc822_message_header();
    my $subject = $header->get('subject');
    my $pragma  = $header->get('x-ticket-pragma') || '';

    my $content = '';
    my $message = $msg->get_first_plaintext_message();
    if (ref($message) eq 'Mail::Message') {
	$content = $message->data_in_body_part();
    }
    else {
	croak("invalid object");
    }

    if ($content =~ /^\s*close/ || 
	$subject =~ /^\s*close/ || 
	$pragma  =~ /close/      ) {
	$self->{ _status } = "closed";
	$self->_append_ticket_status_info("closed");
	Log("ticket is closed");
    }
    else {
	Log("ticket status not changed");
    }
}


# Descriptions: create regexp for a subject tag, for example
#               "[%s %05d]" => "\[\S+ \d+\]"
#    Arguments: a subject tag string
#               XXX non OO type function
# Side Effects: none
# Return Value: a regexp for the given tag
sub _regexp_compile
{
    my ($s) = @_;

    $s = quotemeta( $s );
    $s =~ s@\\\%@\%@g;
    $s =~ s@\%s@\\S+@g;
    $s =~ s@\%d@\\d+@g;
    $s =~ s@\%0\d+d@\\d+@g;
    $s =~ s@\%\d+d@\\d+@g;
    $s =~ s@\%\-\d+d@\\d+@g;

    # quote for regexp substitute: [ something ] -> \[ something \]
    # $s =~ s/^(.)/quotemeta($1)/e;
    # $s =~ s/(.)$/quotemeta($1)/e;

    return $s;
}


sub _extract_message_id_references
{
    my ($header) = @_;
    my $buf = 
        $header->get('in-reply-to') ."\n". $header->get('references');

    use Mail::Address;
    my @addrs = Mail::Address->parse($buf);

    my @r    = ();
    my %uniq = ();
    foreach my $addr (@addrs) { 
        my $a = $addr->address;
        unless ($uniq{ $a }) {
            push(@r, $addr->address);
            $uniq{ $a } = 1;
        }
    }

    \@r;
}


sub _extract_ticket_id_in_subject
{
    my ($self, $header, $config) = @_;
    my $tag     = $config->{ ticket_subject_tag };
    my $subject = $header->get('subject');
    my $regexp  = _regexp_compile($tag);

    # Subject: ... [ticket_id]
    if (($config->{ ticket_subject_tag_location } eq 'appended') &&
	($subject =~ /($regexp)\s*$/)) {
	my $id = $1;
	$id =~ s/^(\[|\(|\{)//;
	$id =~ s/(\]|\)|\})$//;
	return $id;
    }
    # XXX incomplete, we check subject after cutting off "Re:" et. al.
    # Subject: [ticket_id] ...
    # Subject: Re: [ticket_id] ...
    elsif (($config->{ ticket_subject_tag_location } eq 'appended') &&
	   ($subject =~ /^\s*($regexp)/)) {
	my $id = $1;
	$id =~ s/^(\[|\(|\{)//;
	$id =~ s/(\]|\)|\})$//;
	return $id;
    }
    else {
	Log("no ticket id /$regexp/ in subject");
	return 0;
    }
}


sub _get_ticket_id
{
    my ($self, $header, $config, $id) = @_;
    my $subject_tag = $config->{ ticket_subject_tag };
    my $id_syntax   = $config->{ ticket_id_syntax };

    # ticket_id in subject
    my $ticket_id = sprintf($subject_tag, $id);
    $self->{ _ticket_subject_tag } = $ticket_id;

    $ticket_id = sprintf($id_syntax, $id);
    $self->{ _ticket_id } = $ticket_id;

    return $ticket_id;
}


sub _rewrite_header
{
    my ($self, $header, $config, $id) = @_;

    # append the ticket tag to the subject
    my $subject = $header->get('subject') || '';
    $header->replace('Subject', 
		     $subject." " . $self->{ _ticket_subject_tag });
}


# clean up given C<address>.
# It parse it by C<Mail::Address::parse()> and nuke < and >.
sub _address_clean_up
{
    my ($self, $addr) = @_;

    use Mail::Address;
    my @addrlist = Mail::Address->parse($addr);

    # only the first element in the @addrlist array is effective.
    $addr = $addrlist[0]->address;
    $addr =~ s/^\s*<//;
    $addr =~ s/>\s*$//;

    # return the result.
    return $addr;
}


=head2 update_db($msg)

=cut


sub update_db
{
    my ($self, $msg) = @_;
    my $config  = $self->{ _config };
    my $ml_name = $config->{ ml_name };

    return if $self->{ _pragma } eq 'ignore';

    $self->db_open();

    # save $ticke_id et.al. in db_dir/$ml_name
    $self->_update_db($msg);

    # save cross reference pointers among $ml_name
    $self->_update_index_db();

    $self->db_close();
}


sub _update_db
{
    my ($self, $msg) = @_;
    my $config     = $self->{ _config };
    my $pcb        = $self->{ _pcb };
    my $article_id = $pcb->{'article'}->{'id'};
    my $ticket_id  = $self->{ _ticket_id };

    # 0. logging
    Log("article_id=$article_id ticket_id=$ticket_id");

    # prepare hash table tied to db_dir/*db's
    my $rh = $self->{ _hash_table };

    # 1. 
    $rh->{ _ticket_id }->{ $article_id }  = $ticket_id;
    $rh->{ _date      }->{ $article_id }  = time;
    $rh->{ _articles  }->{ $ticket_id  } .= $article_id . " ";

    # 2. record the sender information
    my $header = $msg->rfc822_message_header;
    $rh->{ _sender }->{ $article_id } = $header->get('from');

    # 3. update status information
    if (defined $self->{ _status }) {
	$self->_set_status($ticket_id, $self->{ _status });
    }
    else {
	# set the default status value for the first time.
	unless (defined $rh->{ _status }->{ $ticket_id }) {
	    $self->_set_status($ticket_id, 'open');
	}
    }

    # 4. save optional/additional information
    #    message_id hash is { message_id => ticket_id };
    my $mid = $header->get('message-id');
    $mid    = $self->_address_clean_up($mid);
    $rh->{ _message_id }->{ $mid } = $ticket_id;

    # 5. history
    my $buf    = '';
    my (@aid)  = split(/\s+/, $rh->{ _articles  }->{ $ticket_id });
    my $sender = $rh->{ _sender }->{ $aid[0] };
    my $when   = $rh->{ _date }->{ $aid[0] };

    # clean up
    $sender =~ s/[\s\n]*$//;
    $when   =~ s/[\s\n]*$//;

    use Mail::Message::Date;
    $when = Mail::Message::Date->new($when)->mail_header_style();
    
    $buf .= "\t\n";
    $buf .= "\tthis ticket/thread is opended at article $aid[0]\n";
    $buf .= "\tby $sender\n";
    $buf .= "\ton $when\n";
    $buf .= "\tarticle references: @aid\n";
    $self->{ _status_history } = $buf;
}


# register myself to index_db for further reference among mailing lists
sub _update_index_db
{
    my ($self) = @_;
    my $config    = $self->{ _config };
    my $ticket_id = $self->{ _ticket_id };
    my $rh        = $self->{ _hash_table };
    my $ml_name   = $config->{ ml_name };

    my $ref = $rh->{ _index }->{ $ticket_id } || '';
    if ($ref !~ /^$ml_name|\s$ml_name\s|$ml_name$/) {
	$rh->{ _index }->{ $ticket_id } .= $ml_name." ";
    }
}


=head2 C<set_status($args)>

set $status for $ticket_id. It rewrites DB (file).
C<$args>, HASH reference, must have two keys.

    $args = {
	ticket_id => $ticket_id,
	status    => $status,
    }

C<set_status()> calls db_open() an db_close() automatically within it.

=cut


# Descriptions: 
#    Arguments: $self $curproc $args
# Side Effects: 
# Return Value: none
sub set_status
{
    my ($self, $args) = @_;
    my $ticket_id = $args->{ ticket_id };
    my $status    = $args->{ status };

    Log("ticket.set_status($ticket_id, $status)");

    $self->db_open();
    $self->_set_status($ticket_id, $status);
    $self->db_close();
}


sub _set_status
{
    my ($self, $ticket_id, $value) = @_;
    $self->{ _hash_table }->{ _status }->{ $ticket_id } = $value;
}


sub Log
{
    print STDERR "Log> @_\n";
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

Mail::ThreadTrack::Analyze appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
