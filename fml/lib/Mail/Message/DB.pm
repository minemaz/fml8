#-*- perl -*-
#
#  Copyright (C) 2003 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML$
#

package Mail::Message::DB;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

use lib qw(../../../../fml/lib
	   ../../../../cpan/lib
	   ../../../../img/lib
	   );

my $version = q$FML$;
if ($version =~ /,v\s+([\d\.]+)\s+/) { $version = $1;}

my $debug = 1;

my $keepalive = 1;

my (@table_list) = qw(
		      from who date subject to cc reply_to

		      message_id
		      message_id_to_key
		      message_id_to_key_list

		      ref_key_list
		      next_key
		      prev_key
		      monthly_to_key_list

		      filename
		      filepath
		      subdir

		      month 
		      hint
		      );



=head1 NAME

Mail::Message::DB - DB interface

=head1 SYNOPSIS

  ... lock by something ...

  ... unlock by something ...

This module itself provides no lock function.
please use flock() built in perl or CPAN lock modules for it.

=head1 DESCRIPTION

=head1 METHODS

=head2 C<new($args)>

    my $args = {
	db_module    => 'AnyDBM_File',
	db_base_dir  => '/var/spool/ml/@udb@/thread',
	db_name      => 'elena',  # mailing list identifier
	key          => 100,      # article sequence number
    };

In fml 8 case, C<table> not needs the full mail address such as
C<elena@fml.org> since fml uses different $db_base_dir for each
domain.

For example, this module creates/updates the following databases (e.g.
/$db_base_dir/$db_name/$table.db where $table is 'article', '
message_id', 'sender', et.al.).

   /var/spool/ml/@udb@/thread/elena/articles.db
   /var/spool/ml/@udb@/thread/elena/date.db
   /var/spool/ml/@udb@/thread/elena/message_id.db
   /var/spool/ml/@udb@/thread/elena/sender.db
   /var/spool/ml/@udb@/thread/elena/status.db
   /var/spool/ml/@udb@/thread/elena/thread_id.db

Almost all tables use $key (article sequence number) as primary key
since it is unique in the mailing list articles.

    # key => filepath
    $article = {
	100 => /var/spool/ml/elena/spool/100,
	101 => /var/spool/ml/elena/spool/101,
    };

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, $args) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};

    # initialize DB module backend
    set_db_module_name($me, $args->{ db_module } || 'AnyDBM_File');

    # db_base_dir = /var/spool/ml/@udb@/elena
    set_db_base_dir($me,
		    $args->{ db_base_dir } || croak("specify db_base_dir"));

    # $db_name/$table uses $key as primary key.
    set_db_name($me, $args->{ db_name }) if defined $args->{ db_name };
    set_key($me,     $args->{ key })     if defined $args->{ key };
		
    return bless $me, $type;
}


# Descriptions: destructor.
#    Arguments: OBJ($self)
# Side Effects: close db
# Return Value: none
sub DESTROY
{
    my ($self) = @_;

    if (defined $self->{ _db }) {
	$self->db_close();
    }
}


=head1 PARSE and ANALYZE

=cut


# Descriptions: update database on message header, thread relation
#               et. al.
#    Arguments: OBJ($self) OBJ($msg) HASH_REF($args)
# Side Effects: update database
# Return Value: none
sub analyze
{
    my ($self, $msg) = @_;
    my $hdr      = $msg->whole_message_header;
    my $date     = $hdr->get('date');     $date    =~ s/\s*$//;
    my $to       = $hdr->get('to');       $to      =~ s/\s*$//;
    my $cc       = $hdr->get('cc');       $cc      =~ s/\s*$//;
    my $replyto  = $hdr->get('reply-to'); $replyto =~ s/\s*$//;
    my $subject  = $hdr->get('subject');  $subject =~ s/\s*$//;
    my $id       = $self->get_key();
    my $month    = $self->msg_time($hdr, 'yyyy/mm');
    my $subdir   = $self->msg_time($hdr, 'yyyymm');
    my $_subject = $self->_decode_mime_string($subject);
    my $who      = $self->_who_of_address( $hdr->get('from') );
    my $ra_from  = $self->_address_clean_up( $hdr->get('from') );
    my $ra_mid   = $self->_address_clean_up( $hdr->get('message-id') );
    my $from     = $ra_from->[0] || 'unknown';
    my $mid      = $ra_mid->[0]  || '';

    my $db = $self->db_open();

    $self->_update_id_max($db, $id);

    $self->_db_set($db, 'date',     $id, $date);     # Sun Jun 1 13:46:15 ...
    $self->_db_set($db, 'from',     $id, $from);     # rudo@nuinui.net
    $self->_db_set($db, 'reply_to', $id, $replyto);  # a@b
    $self->_db_set($db, 'who',      $id, $who);      # Rudolf Shumidt
    $self->_db_set($db, 'subject',  $id, $_subject); # subject string ...
    $self->_db_set($db, 'to',       $id, $to);       # a@b
    $self->_db_set($db, 'cc',       $id, $cc);       # a@b
    $self->_db_set($db, 'month',    $id, $month);    # 2003/06
    $self->_db_set($db, 'subdir',   $id, $subdir);   # 200306
    $self->_db_set($db, 'id',       $id, $id);       # 100

    if ($mid) {
	$self->_db_set($db, 'message_id',        $id, $mid); # 20030601rudo@nui
	$self->_db_set($db, 'message_id_to_key', $mid, $id); # REVERSE_MAP

	# { message_id => id1 id2 id3 ... } where id* refers this $mid.
	$self->_db_add_list_entry($db, 'message_id_to_key_list', $mid, $id);
    }

    # HASH { YYYY/MM => (id1 id2 id3 ..) }
    $self->_db_add_list_entry($db, 'monthly_to_key_list', $month, $id);

    $self->_analyze_thread($db, $msg, $hdr);

    unless ($keepalive) {
	$self->db_close();
    }
}


# Descriptions: update $id_max in hint.
#    Arguments: OBJ($self) HASH_REF($db) NUM($id)
# Side Effects: update hint in $db
# Return Value: none
sub _update_id_max
{
    my ($self, $db, $id) = @_;

    # we should not update max_id when our target is an attachment.
    # update max_id only under the top level operation
    unless ($self->{ _is_attachment }) {
	_PRINT_DEBUG("mode = parent");

	my $id_max = $self->_db_get($db, 'hint', 'id_max') || 0;
	if (defined $id_max && $id_max) {
	    my $value = $id_max < $id ? $id : $id_max;
	    $self->_db_set($db, 'hint', 'id_max', $value);
	}
	else {
	    $self->_db_set($db, 'hint', 'id_max', $id);
	}
    }
    else {
	_PRINT_DEBUG("mode = child");
    }
}


# Descriptions: analyze thread information based on
#                In-Reply-To: and References.
#    Arguments: OBJ($self) HASH_REF($db) OBJ($msg) OBJ($hdr)
# Side Effects: update db
# Return Value: none
sub _analyze_thread
{
    my ($self, $db, $msg, $hdr) = @_;
    my $id           = $self->get_key();
    my $ra_ref       = $self->_address_clean_up($hdr->get('references'));
    my $ra_inreplyto = $self->_address_clean_up($hdr->get('in-reply-to'));
    my $in_reply_to  = $ra_inreplyto->[0] || '';

    # I. prepare and save thread related information 
    #   1. analyze In-Reply-To: and prepare REVERSE MAP for them.
    #   2. apply the same logic for all message-id's in References:
    my %uniq  = ();
    my $count = 0;

  MSGID_SEARCH:
    for my $mid (@$ra_inreplyto, @$ra_ref) {
	next MSGID_SEARCH unless defined $mid;

	# ensure uniqueness
	_PRINT_DEBUG("DUP: $mid") if $uniq{$mid};
	next MSGID_SEARCH if $uniq{$mid};
	$uniq{$mid} = 1;
	$count++;

	# REVERSE_MAP { message-id => (id1 id2 id3 ...)
	$self->_db_add_list_entry($db, 'message_id_to_key_list', $mid, $id);

	# we extract id1 from MAP { message-id => $idlist = (id1 id2 id3 ...) }
	# and define id1 = $head_id.
	# XXX $id_list is not ARRAY but STR such as "id1 id2 id3 ...";
	my $id_list = $self->_db_get($db, 'message_id_to_key_list', $mid);
	my $head_id = _head_of_list_str($id_list) || 0;

	# REVERSE_MAP { head_id(id1) => (id1 id2 id3 ...) }
	if ($head_id && $head_id != $id) {
	    $self->_db_add_list_entry($db, 'ref_key_list', $head_id, $id);
	    _PRINT_DEBUG("THREAD SEARCH: $head_id => $id ($id_list)");
	}
	else {
	    _PRINT_DEBUG("THREAD SEARCH: NOT FOUND");
	}
    }

    unless ($count) {
	_PRINT_DEBUG("THREAD SEARCH: NOT TRY");
    }

    # II. ok. go to speculate prev/next links
    #   1. If In-Reply-To: is found, use it as "pointer to previous id"
    my $idp = 0;
    if (defined $in_reply_to) {
	# XXX idp (id pointer) = id1 by _head_of_list_str( (id1 id2 id3 ...)
	my $id_list = 
	    $self->_db_get($db, 'message_id_to_key_list', $in_reply_to);
	$idp = _head_of_list_str($id_list);
    }
    # 2. if not found, try to use References: "in reverse order"
    elsif (@$ra_ref) {
	my (@rra) = reverse(@$ra_ref);
	$idp = $rra[0];
    }
    # 3. no link to previous one found
    else {
	$idp = 0;
    }

    # 4. if $idp (link to previous message) found, 
    if (defined($idp) && $idp && $idp =~ /^\d+$/) {
	if ($idp != $id) {
	    $self->_db_set($db, 'prev_key', $id, $idp);
	}

	# We should not overwrite "id => next_key" assinged already.
	# We should preserve the first "id => next_key" value.
	# but we may overwride it if "id => id (itself)", wrong link.
	my $nid = $self->_db_get($db, 'next_key', $idp) || 0;
	unless ($nid && $nid != $idp && $id != $idp) {
	    $self->_db_set($db, 'next_key', $idp, $id);
	}
    }
    else {
	_PRINT_DEBUG("no prev thread link (id=$id)");
    }
}


=head1 UTILITY FUNCTIONS

All methods are module internal.

=cut


# Descriptions: convert space-separeted string to array
#    Arguments: STR($str)
# Side Effects: none
# Return Value: ARRAY_REF
sub _str_to_array_ref
{
    my ($str) = @_;

    return undef unless defined $str;

    $str =~ s/^\s*//;
    $str =~ s/\s*$//;
    my (@a) = split(/\s+/, $str);
    return \@a;
}


# Descriptions: add { key => value } into $table with converting
#               where value is "x y z ..." form, space separated string.
#    Arguments: HASH_REF($db) STR($dbname) STR($key) STR($value)
# Side Effects: update database
# Return Value: none
sub _db_add_list_entry
{
    my ($self, $db, $table, $key, $value) = @_;
    my $found = 0;
    my $ra    = _str_to_array_ref($db->{ $table }->{ $key }) || [];

    if (defined($key) && $key && defined($value) && $value) {
	# check duplication to ensure uniqueness within this array.
	for my $v (@$ra) {
	    $found = 1 if ($value =~ /^\d+$/o) && ($v == $value);
	    $found = 1 if ($value !~ /^\d+$/o) && ($v eq $value);
	}
	
	# add if the value is a new comer.
	unless ($found) {
	    my $v = $self->_db_get($db, $table, $key) || '';
	    $v .= $v ? " $value" : $value;
	    $self->_db_set($db, $table, $key, $v);
	}
    }
}


# Descriptions: head of array (space separeted string)
#    Arguments: STR($buf)
# Side Effects: none
# Return Value: STR
sub _head_of_list_str
{
    my ($buf) = @_;
    $buf =~ s/^\s*//;
    $buf =~ s/\s*$//;

    return (split(/\s+/, $buf))[0];
}


# Descriptions: decode mime string.
#    Arguments: OBJ($self) STR($str) STR($out_code) STR($in_code)
# Side Effects: none
# Return Value: STR
sub _decode_mime_string
{
    my ($self, $str, $out_code, $in_code) = @_;

    use Mail::Message::Encode;
    my $encode = new Mail::Message::Encode;
    return $encode->decode_mime_string($str, $out_code, $in_code);
}


# Descriptions: return formated time of message Date:
#    Arguments: OBJ($self) STR($type)
# Side Effects: none
# Return Value: STR
sub msg_time
{
    my ($self, $hdr, $type) = @_;

    if (defined($hdr) && $hdr->get('date')) {
	use Time::ParseDate;
	my $unixtime = parsedate( $hdr->get('date') );
	my ($sec,$min,$hour,$mday,$mon,$year,$wday) = localtime( $unixtime );

	if ($type eq 'yyyymm') {
	    return sprintf("%04d%02d", 1900 + $year, $mon + 1);
	}
	elsif ($type eq 'yyyy/mm') {
	    return sprintf("%04d/%02d", 1900 + $year, $mon + 1);
	}
    }
    else {
	my $id = $self->{ _current_id };
	warn("cannot pick up Date: field id=$id");
	return '';
    }
}


# Descriptions: clean up email address by Mail::Address.
#               return clean-up'ed address list.
#    Arguments: STR($addr)
# Side Effects: none
# Return Value: ARRAY_REF
sub _address_clean_up
{
    my ($self, $addr) = @_;
    my (@r);

    use Mail::Address;
    my (@addrs) = Mail::Address->parse($addr);

    my $i = 0;
  LIST:
    for my $addr (@addrs) {
	my $xaddr = $addr->address();
	next LIST unless $xaddr =~ /\@/;
	push(@r, $xaddr);
    }

    return \@r;
}


# Descriptions: extrace gecos field in $address
#    Arguments: OBJ($self) STR($address)
# Side Effects: none
# Return Value: STR
sub _who_of_address
{
    my ($self, $address) = @_;
    my ($user);

    use Mail::Address;
    my (@addrs) = Mail::Address->parse($address);

    for my $addr (@addrs) {
	if (defined( $addr->phrase() )) {
	    my $phrase = $self->_decode_mime_string( $addr->phrase() );

	    if ($phrase) {
		return($phrase);
	    }
	}

	$user = $addr->user();
    }

    return( $user ? "$user\@xxx.xxx.xxx.xxx" : $address );
}


=head1 DATABASE PARAMETERS MANIPULATION

=cut


# Descriptions: open database
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: tied with $self->{ _db }
#         Todo: we should use IO::Adapter ?
# Return Value: none
sub db_open
{
    my ($self, $args) = @_;

    return $self->{ _db } if defined $self->{ _db };

    my $db_type   = $self->get_db_module_name();
    my $db_dir    = $self->get_db_base_dir();
    my $file_mode = $self->{ _file_mode } || 0644;

    _PRINT_DEBUG("db_open( type = $db_type )");

    eval qq{ use $db_type; use Fcntl;};
    unless ($@) {
 	for my $db (@table_list) {
	    my $file = "$db_dir/${db}";
	    my $str = qq{
		my \%$db = ();
		tie \%$db, \$db_type, \$file, O_RDWR|O_CREAT, $file_mode;
		\$self->{ _db }->{ '_$db' } = \\\%$db;
	    };
	    eval $str;
	    croak($@) if $@;
	}
    }
    else {
	croak("cannot use $db_type");
    }

    $self->{ _db } || undef;
}


# Descriptions: close database
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: untie $self->{ _db }
#         Todo: we should use IO::Adapter ?
# Return Value: none
sub db_close
{
    my ($self, $args) = @_;
    my $db_type = $args->{ db_type } || $self->{ _db_type } || 'AnyDBM_File';
    my $db_dir  = $self->{ _html_base_directory };

    _PRINT_DEBUG("db_close()");

    for my $db (@table_list) {
	my $str = qq{
	    my \$${db} = \$self->{ _db }->{ '_$db' };
	    untie \%\$${db};
	};
	eval $str;
	croak($@) if $@;
    }

    delete $self->{ _db } if defined $self->{ _db };
}


sub set
{
    my ($self, $table, $key, $value) = @_;
    my $db = $self->db_open();

    $self->_db_set($db, $table, $key, $value);
}


sub get
{
    my ($self, $table, $key) = @_;
    my $db = $self->db_open();

    return $self->_db_get($db, $table, $key);
}


sub _db_set
{
    my ($self, $db, $table, $key, $value) = @_;

    if (defined $value && $value) {
	_PRINT_DEBUG("db: table=$table { $key => $value }");
	$db->{ "_$table" }->{ $key } = $value;
    }
}


sub _db_get
{
    my ($self, $db, $table, $key) = @_;

    return( $db->{ "_$table" }->{ $key } || '' );
}


sub set_db_module_name
{
    my ($self, $module) = @_;

    $self->{ _db_module } = $module if defined $module;
}


sub get_db_module_name
{
    my ($self) = @_;

    return( $self->{ _db_module } || undef );
}


sub set_db_base_dir
{
    my ($self, $dir) = @_;

    $self->{ _db_base_dir } = $dir if defined $dir;
}


sub get_db_base_dir
{
    my ($self) = @_;

    return( $self->{ _db_base_dir } || undef );
}


sub set_db_name
{
    my ($self, $name) = @_;

    $self->{ _db_name } = $name if defined $name;
}


sub get_db_name
{
    my ($self) = @_;

    return( $self->{ _db_name } || undef );
}


sub set_key
{
    my ($self, $key) = @_;

    $self->{ _key } = $key if defined $key;
}


sub get_key
{
    my ($self) = @_;

    return( $self->{ _key } || undef );
}



=head1 DEBUG

=cut

# Descriptions: debug
#    Arguments: STR($str)
# Side Effects: none
# Return Value: none
sub _PRINT_DEBUG
{
    my ($str) = @_;
    print STDERR "(debug) $str\n" if $debug;
}


# Descriptions: debug, print out hash
#    Arguments: HASH_REF($hash)
# Side Effects: none
# Return Value: none
sub _PRINT_DEBUG_DUMP_HASH
{
    my ($hash) = @_;
    my ($k,$v);

    if ($debug) {
	while (($k, $v) = each %$hash) {
	    printf STDERR "%-30s => %s\n", $k, $v;
	}
    }
}


#
# DEBUG
#
if ($0 eq __FILE__) {
    my $args = {
	db_module    => 'AnyDBM_File',
	db_base_dir  => '/tmp',
	db_name      => 'elena',  # mailing list identifier
	key          => 100,      # article sequence number
    };

    my $obj = new Mail::Message::DB $args;

    for my $file (@ARGV) {
	use File::Basename;
	my $id = basename($file);

	use Mail::Message;
	my $msg = Mail::Message->parse( { file => $file } );
	$obj->set_key($id);
	$obj->analyze($msg);
    }
}


=head1 TODO

=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2003 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

Mail::Message::DB first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

This class is renamed from C<Mail::HTML::Lite> 1.40 (2001-2002).

=cut


1;
