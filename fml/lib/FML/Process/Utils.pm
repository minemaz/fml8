#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Utils.pm,v 1.53 2003/01/11 16:05:20 fukachan Exp $
#

package FML::Process::Utils;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use FML::Log qw(Log LogWarn LogError);


=head1 NAME

FML::Process::Utils - convenient utilities for FML::Process:: classes

=head1 SYNOPSIS

See L<FML::Process::Kernel>.

=head1 DESCRIPTION

See FML:: classes, which uses these function everywhere.

=head1 access METHODS to handle configuration space

=head2 config()

return FML::Config object.

=head2 pcb()

return FML::PCB object.

=head2 schduler()

return FML::Process::Scheduler object.

=cut


# Descriptions: return FML::Config object
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: OBJ
sub config
{
    my ($curproc) = @_;

    if (defined $curproc->{ config }) {
	return $curproc->{ config };
    }
    else {
	return undef;
    }
}


# Descriptions: return FML::PCB object
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: OBJ
sub pcb
{
    my ($curproc) = @_;

    if (defined $curproc->{ pcb }) {
	return $curproc->{ pcb };
    }
    else {
	return undef;
    }
}


# Descriptions: return FML::Process::Scheduler object
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: OBJ
sub scheduler
{
    my ($curproc) = @_;

    if (defined $curproc->{ scheduler }) {
	return $curproc->{ scheduler };
    }
    else {
	return undef;
    }
}


=head1 access METHODS to handle incoming_message

available all processes which eats message via STDIN.

The following functions return the whole or a part of the incoming
message corresponding to the current process.

The message is a chain of C<Mail::Message> objects such as

   header -> body

   header -> multipart-preamble -> multipart-separator -> part1 -> ...

See L<Mail::Message> for more details.

=head2 incoming_message_header()

return the header part for the incoming message.
It is the head of a chain of Mail::Message objects.

=head2 incoming_message_body()

return the body part for the incoming message.
It is the 2nd part of a chain of Mail::Message objects and after.
For example,

   body

   multipart-preamble -> multipart-separator -> part1 -> ...

=head2 incoming_message()

return the whole message for the incoming message.
It is the whole parts of a chain.

=cut


# Descriptions: return incoming_message header object if could
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: OBJ
sub incoming_message_header
{
    my ($curproc) = @_;

    if (defined $curproc->{ incoming_message }->{ header }) {
	return $curproc->{ incoming_message }->{ header };
    }
    else {
	return undef;
    }
}


# Descriptions: return incoming_message body object if could
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: OBJ
sub incoming_message_body
{
    my ($curproc) = @_;

    if (defined $curproc->{ incoming_message }->{ body }) {
	return $curproc->{ incoming_message }->{ body };
    }
    else {
	return undef;
    }
}


# Descriptions: return incoming_message message object if could
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: OBJ
sub incoming_message
{
    my ($curproc) = @_;

    if (defined $curproc->{ incoming_message }->{ message }) {
	return $curproc->{ incoming_message }->{ message };
    }
    else {
	return undef;
    }
}


=head1 access METHODS to handle article

available only in C<libexec/distribute> process.

The usage of these functions is same as that of incoming_message_*()
methods but article_*() hanldes the article object to distribute now.
So, incoming_message_*() handles input but article_message_*() handles
output.

=head2 article_message_header()

=head2 article_message_body()

=head2 article_message()

=cut


# Descriptions: return article header object if could
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: OBJ
sub article_message_header
{
    my ($curproc) = @_;

    if (defined $curproc->{ article }->{ header }) {
	return $curproc->{ article }->{ header };
    }
    else {
	LogError("\$curproc->{ article }->{ header } not defined");
	return undef;
    }
}


# Descriptions: return article body object if could
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: OBJ
sub article_message_body
{
    my ($curproc) = @_;

    if (defined $curproc->{ article }->{ body }) {
	return $curproc->{ article }->{ body };
    }
    else {
	LogError("\$curproc->{ article }->{ body } not defined");
	return undef;
    }
}


# Descriptions: return article message object if could
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: OBJ
sub article_message
{
    my ($curproc) = @_;

    if (defined $curproc->{ article }->{ message }) {
	return $curproc->{ article }->{ message };
    }
    else {
	LogError("\$curproc->{ article }->{ message } not defined");
	return undef;
    }
}


=head1 misc METHODS

=head2 mkdir($dir, $mode)

create directory $dir if needed.

=cut

#
# XXX-TODO: $curproc->mkdir() is strage.
# XXX-TODO: hmm, we create a new subcleass such as $curproc->util->mkdir() ?
# XXX-TODO: or $utils = $curproc->utils(); $utils->mkdir(dir, mode); ?
# XXX-TODO: we need FML::Utils class ?
#

# Descriptions: create directory $dir if needed
#    Arguments: OBJ($curproc) STR($dir) STR($mode)
# Side Effects: create directory $dir
# Return Value: NUM(1 or 0)
sub mkdir
{
    my ($curproc, $dir, $mode) = @_;
    my $config  = $curproc->config();
    my $dirmode = $config->{ default_directory_mode } || '0700';

    # back up umask
    my $curmask = umask( 077 ); # full open for readability

    unless (-d $dir) {
	if (defined $mode) {
	    if ($mode =~ /^\d+$/) { # NUM 0700
		_mkpath_num($dir, $mode);
	    }
	    elsif ($mode =~ /mode=(\S+)/) {
		my $xmode = "directory_${1}_mode";
		if (defined $config->{ $xmode }) {
		    _mkpath_str($dir, $config->{ $xmode });
		}
		else {
		    LogError("mkdir: invalid mode");
		}
	    }
	    else {
		LogError("mkdir: invalid mode");
	    }
	}
	elsif ($dirmode =~ /^\d+$/) { # STR 0700
	    _mkpath_str($dir, $dirmode);
	}
	else {
	    LogError("mkdir: invalid mode");
	}
    }

    return( -d $dir ? 1 : 0 );
}


# Descriptions: mkdir with the specified dir mode
#    Arguments: STR($dir) NUM($mode)
# Side Effects: mkdir && chmod
# Return Value: none
sub _mkpath_num
{
    my ($dir, $mode) = @_;
    my $cur_mask = umask();

    umask(0);

    if ($mode =~ /^\d+$/) { # NUM 0700
	eval q{ use File::Path;};
	mkpath([ $dir ], 0, $mode);
	chmod $mode, $dir;
	Log(sprintf("mkdir %s mode=0%o", $dir, $mode));
    }
    else {
	LogError("mkdir: invalid mode (N)");
    }

    umask($cur_mask);
}


# Descriptions: mkdir with the specified dir mode
#    Arguments: STR($dir) STR($mode)
# Side Effects: mkdir && chmod
# Return Value: none
sub _mkpath_str
{
    my ($dir, $mode) = @_;
    my $cur_mask = umask();

    umask(0);

    if ($mode =~ /^\d+$/) { # STR 0700
	eval qq{
	    use File::Path;
	    mkpath([ \$dir ], 0, $mode);
	    chmod $mode, \$dir;
	    Log(\"mkdirhier \$dir mode=$mode\");
	};
	LogError($@) if $@;
    }
    else {
	LogError("mkdir: invalid mode (S)");
    }

    umask($cur_mask);
}


=head1 METHODS for convenience

=head2 fml_version()

return fml version.

=head2 fml_owner()

return fml owner.

=head2 fml_group()

return fml group.

=head2 myname()

return the current process name.

=head2 command_line_raw_argv()

return @ARGV before getopts() analyze.

=head2 command_line_argv()

return @ARGV after getopts() analyze.

=head2 command_line_argv_find(pat)

return the matched pattern in @ARGV and return it if found.

=head2 command_line_options()

return options, result of getopts() analyze.

=cut


# Descriptions: return fml version
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub fml_version
{
    my ($curproc) = @_;
    my $args = $curproc->{ __parent_args };

    return $args->{ main_cf }->{ fml_version };
}


# Descriptions: return fml owner
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub fml_owner
{
    my ($curproc) = @_;
    my $args = $curproc->{ __parent_args };

    return $args->{ main_cf }->{ fml_owner };
}


# Descriptions: return fml group
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub fml_group
{
    my ($curproc) = @_;
    my $args = $curproc->{ __parent_args };

    return $args->{ main_cf }->{ fml_group };
}


# Descriptions: return the current process name
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub myname
{
    my ($curproc) = @_;
    my $args = $curproc->{ __parent_args };

    return $args->{ myname };
}


# Descriptions: return raw @ARGV of the current process,
#               where @ARGV is before getopts() applied
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: ARRAY_REF
sub command_line_raw_argv
{
    my ($curproc) = @_;
    my $args = $curproc->{ __parent_args };

    return $args->{ argv };
}


# Descriptions: return @ARGV of the current process,
#               where @ARGV is after getopts() applied
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: ARRAY_REF
sub command_line_argv
{
    my ($curproc) = @_;
    my $args = $curproc->{ __parent_args };

    return $args->{ ARGV };
}


# Descriptions: return a string matched with the specified pattern and
#               return it.
#    Arguments: OBJ($curproc) STR($pat)
# Side Effects: none
# Return Value: STR
sub command_line_argv_find
{
    my ($curproc, $pat) = @_;
    my $argv = $curproc->command_line_argv();

    if (defined $pat) {
	for my $x (@$argv) {
	    if ($x =~ /^$pat/) {
		return $1;
	    }
	}
    }

    return undef;
}


# Descriptions: return options, which is the result by getopts() analyze
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: ARRAY_REF
sub command_line_options
{
    my ($curproc) = @_;
    my $args = $curproc->{ __parent_args };

    return $args->{ options };
}


=head2 ml_name()

not yet implemenetd properly. (?)

=cut


# Descriptions: return ml_name
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub ml_name
{
    my ($curproc) = @_;
    my $config = $curproc->{ config };

    if (defined $config->{ ml_name } && $config->{ ml_name }) {
	return $config->{ ml_name };
    }
    else {
	croak("\$ml_name not defined.");
    }
}


=head2 ml_domain()

return the domain handled in the current process. If not defined
properly, return the default domain defined in /etc/fml/main.cf.

=cut


# Descriptions: return my domain
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub ml_domain
{
    my ($curproc) = @_;
    my $config = $curproc->{ config };

    if (defined $config->{ ml_domain } && $config->{ ml_domain }) {
	return $config->{ ml_domain };
    }
    else {
	return $curproc->default_domain();
    }
}


=head2 default_domain()

return the default domain defined in /etc/fml/main.cf.

=cut


# Descriptions: return the default domain defined in /etc/fml/main.cf.
#    Arguments: OBJ($curproc) STR($domain)
# Side Effects: none
# Return Value: STR
sub default_domain
{
    my ($curproc, $domain) = @_;
    my $main_cf = $curproc->{ __parent_args }->{ main_cf };

    return $main_cf->{ default_domain };
}


# Descriptions: check if $domain is the default one or not.
#               This is used to check $domain is a virtual domain or not.
#    Arguments: OBJ($curproc) STR($domain)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub is_default_domain
{
    my ($curproc, $domain) = @_;
    my $default_domain = $curproc->default_domain();

    # XXX domain name is case insensitive.
    if ("\L$domain\E" eq "\L$default_domain\E") {
	return 1;
    }
    else {
	return 0;
    }
}


=head2 executable_prefix()

return executable prefix such as "/usr/local".

=cut


# Descriptions: return the path for executables
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub executable_prefix
{
    my ($curproc) = @_;
    my $main_cf = $curproc->{ __parent_args }->{ main_cf };

    return $main_cf->{ executable_prefix };
}


=head2 template_files_dir_for_newml()

return the path where template files used in "newml" method exist.

=cut


# Descriptions: return the path where template files used
#               in "newml" method exist
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub template_files_dir_for_newml
{
    my ($curproc) = @_;
    my $main_cf = $curproc->{ __parent_args }->{ main_cf };

    return $main_cf->{ default_config_dir };
}


=head2 ml_home_prefix([domain])

return $ml_home_prefix in main.cf.

=cut

# XXX-TODO: __ml_home_prefix_from_main_cf() is not needed.
# XXX-TODO: since FML::Process::Switch calculate this variable and
# XXX-TODO: set it to $curproc->{ main_cf }.


# Descriptions: front end wrapper to retrieve $ml_home_prefix (/var/spool/ml).
#               return $ml_home_prefix defined in main.cf (/etc/fml/main.cf).
#               return $ml_home_prefix for $domain if $domain is specified.
#               return default one if $domain is not specified.
#    Arguments: OBJ($curproc) STR($domain)
# Side Effects: none
# Return Value: STR
sub ml_home_prefix
{
    my ($curproc, $domain) = @_;
    my $main_cf = $curproc->{ __parent_args }->{ main_cf };
    __ml_home_prefix_from_main_cf($main_cf, $domain);
}


# Descriptions: return $ml ML's home directory
#    Arguments: OBJ($curproc) STR($ml) STR($domain)
# Side Effects: none
# Return Value: STR
sub ml_home_dir
{
    my ($curproc, $ml, $domain) = @_;
    my $prefix = $curproc->ml_home_prefix($domain);

    use File::Spec;
    return File::Spec->catfile($prefix, $ml);
}


# Descriptions: return $ml_home_prefix defined in main.cf (/etc/fml/main.cf).
#               return $ml_home_prefix for $domain if $domain is specified.
#               return default one if $domain is not specified.
#    Arguments: HASH_REF($main_cf) STR($domain)
# Side Effects: none
# Return Value: STR
sub __ml_home_prefix_from_main_cf
{
    my ($main_cf, $domain) = @_;
    my $default_domain = $main_cf->{ default_domain };

    if (defined $domain) {
	my $found = '';

	my ($virtual_maps) = __get_virtual_maps($main_cf);
	if (@$virtual_maps) {
	    $found = __ml_home_prefix_search_in_virtual_maps($main_cf,
							     $domain,
							     $virtual_maps);
	}

	if ($found) {
	    return $found;
	}
	else {
	    if ("\L$domain\E" eq "\L$default_domain\E") {
		return $main_cf->{ default_ml_home_prefix };
	    }
	    else {
		croak("ml_home_prefix: unknown domain ($domain)");
	    }
	}
    }
    else {
	# if the domain is given as a hint (CGI)
	if (defined $main_cf->{ _hints }->{ ml_domain }) {

	}
	elsif (defined $main_cf->{ ml_home_prefix }) {
	    return $main_cf->{ ml_home_prefix };
	}
	elsif (defined $main_cf->{ default_ml_home_prefix }) {
	    return $main_cf->{ default_ml_home_prefix };
	}
	else {
	    croak("\${default_,}ml_home_prefix is undefined.");
	}
    }
}


# Descriptions: search virtual domain in $virtual_maps.
#               return $ml_home_prefix for the virtual domain if found.
#    Arguments: HASH_REF($main_cf)
#               STR($virtual_domain)
#               ARRAY_REF($virtual_maps)
#         bugs: currently support the only file type of IO::Adapter.
#               This limit comes from the architecture
#               since this function may be used
#               before $curproc and $config is allocated.
#
#               SUPPORT ONLY FILE TYPE MAPS NOT SQL NOR LDAP.
# Side Effects: none
# Return Value: STR
sub __ml_home_prefix_search_in_virtual_maps
{
    my ($main_cf, $virtual_domain, $virtual_maps) = @_;

    if (@$virtual_maps) {
	my $dir = '';
	eval q{ use IO::Adapter; };
	unless ($@) {
	  MAP:
	    for my $map (@$virtual_maps) {
		# XXX only support file:// map
		my $obj = new IO::Adapter $map;
		if (defined $obj) {
		    $obj->open();
		    $dir = $obj->find("^$virtual_domain");
		}
		last MAP if $dir;
	    }

	    if ($dir) {
		($virtual_domain, $dir) = split(/\s+/, $dir);
		$dir =~ s/[\s\n]*$// if defined $dir;

		# found
		if ($dir) {
		    return $dir; # == $ml_home_prefix
		}
	    }
	}
	else {
	    croak("cannot load IO::Adapter");
	}
    }

    return '';
}


=head2 config_cf_filepath($ml, $domain)

return config.cf path for this $ml ($ml@$domain).

=head2 is_config_cf_exist($ml, $domain)

return 1 if config.cf exists. 0 if not.

=cut


# Descriptions: return $ml ML's config.cf path
#    Arguments: OBJ($curproc) STR($ml) STR($domain)
# Side Effects: none
# Return Value: STR
sub config_cf_filepath
{
    my ($curproc, $ml, $domain) = @_;
    my $prefix = $curproc->ml_home_prefix($domain);

    unless (defined $ml) {
	$ml = $curproc->{ config }->{ ml_name };
    }

    use File::Spec;
    return File::Spec->catfile($prefix, $ml, "config.cf");
}


# Descriptions: return whether $ml ML's config.cf file exists or not.
#    Arguments: OBJ($curproc) STR($ml) STR($domain)
# Side Effects: none
# Return Value: STR
sub is_config_cf_exist
{
    my ($curproc, $ml, $domain) = @_;
    my $f = $curproc->config_cf_filepath($ml, $domain);

    return ( -f $f ? 1 : 0 );
}


=head2 get_virtual_maps()

return virtual maps.

=cut


# Descriptions: return virtual maps as array reference.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: ARRAY_REF
sub get_virtual_maps
{
    my ($curproc) = @_;
    my $main_cf = $curproc->{ __parent_args }->{ main_cf };
    __get_virtual_maps($main_cf);
}


# Descriptions: return virtual maps as array reference.
#    Arguments: HASH_REF($main_cf)
# Side Effects: none
# Return Value: ARRAY_REF
sub __get_virtual_maps
{
    my ($main_cf) = @_;

    if (defined $main_cf->{ virtual_maps } && $main_cf->{ virtual_maps }) {
	my (@r) = ();
	my (@maps) = split(/\s+/, $main_cf->{ virtual_maps });
	for (@maps) {
	    if (-f $_) { push(@r, $_);}
	}
	return \@r;
    }
    else {
	return undef;
    }
}


=head2 get_ml_list()

get ARRAY_REF of valid mailing lists.

=cut


# Descriptions: list up ML's within the specified $ml_domain.
#    Arguments: OBJ($curproc) HASH_REF($args) STR($ml_domain)
# Side Effects: none
# Return Value: ARRAY_REF
sub get_ml_list
{
    my ($curproc, $args, $ml_domain) = @_;
    my $ml_home_prefix = $curproc->ml_home_prefix();

    if (defined $ml_domain) {
	$ml_home_prefix = $curproc->ml_home_prefix($ml_domain);
    }
    else {
	my $xx_domain   = $curproc->ml_domain();
	$ml_home_prefix = $curproc->ml_home_prefix($xx_domain);
    }

    # cheap sanity:
    unless ($ml_home_prefix) {
	croak("get_ml_list: ml_home_prefix undefined");
    }

    use File::Spec;
    use DirHandle;
    my $dh      = new DirHandle $ml_home_prefix;
    my $prefix  = $ml_home_prefix;
    my $cf      = '';
    my @dirlist = ();

    if (defined $dh) {
	use FML::Restriction::Base;
	my $safe    = new FML::Restriction::Base;
	my $ml_name = '';

	while ($ml_name = $dh->read()) {
	    next if $ml_name =~ /^\./o;
	    next if $ml_name =~ /^\@/o;

	    # XXX permit $ml_name matched by FML::Restriction::Base.
	    if ($safe->regexp_match('ml_name', $ml_name)) {
		$cf = File::Spec->catfile($prefix, $ml_name, "config.cf");
		push(@dirlist, $ml_name) if -f $cf;
	    }
	}
	$dh->close;
    }

    @dirlist = sort @dirlist;
    return \@dirlist;
}


=head2 get_address_list( $map )

get ARRAY_REF of address list for the specified map.

=cut


# Descriptions: get address list for the specified map
#    Arguments: OBJ($curproc) STR($map)
# Side Effects: none
# Return Value: ARRAY_REF
sub get_address_list
{
    my ($curproc, $map) = @_;
    my $config = $curproc->{ config };
    my $list   = $config->get_as_array_ref( $map );

    eval q{ use IO::Adapter;};
    unless ($@) {
	my $r = [];

	for my $map (@$list) {
	    my $io  = new IO::Adapter $map, $config;
	    my $key = '';
	    if (defined $io) {
		$io->open();
		while (defined($key = $io->get_next_key())) {
		    push(@$r, $key);
		}
		$io->close();
	    }
	}

	return $r;
    }

    return [];
}


=head2 which_map_nl($map)

which this $map belongs to ?

=cut


# Descriptions: which member of maps is this $map ?
#    Arguments: OBJ($curproc) STR($map)
# Side Effects: none
# Return Value: STR
sub which_map_nl
{
    my ($curproc, $map) = @_;
    my $config = $curproc->{ config };
    my $found  = '';

  SEARCH_MAPS:
    for my $mode (qw(member recipient admin_member digest_recipient)) {
	my $maps = $config->get_as_array_ref("${mode}_maps");
	for my $m (@$maps) {
	    if ($map eq $m) {
		$found = $mode;
		last SEARCH_MAPS;
	    }
	}
    }

    return $found;
}


=head2 article_id_max()

return the current article number (sequence number).

=cut


# Descriptions: return the current article number (sequence number)
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: NUM
sub article_id_max
{
    my ($curproc) = @_;
    my $config   = $curproc->{ config };
    my $seq_file = $config->{ sequence_file };
    my $id       = undef;

    use FileHandle;
    my $fh = new FileHandle $seq_file;
    if (defined $fh) {
	$id = $fh->getline();
	$id =~ s/^\s*//;
	$id =~ s/[\n\s]*$//;
	$fh->close();
    }

    if (defined $id) {
	return( $id =~ /^\d+$/ ? $id : 0 );
    }
    else {
	return 0;
    }
}


=head2 get_print_style()

=head2 set_print_style(mode)

=cut


# Descriptions: get print style
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub get_print_style
{
    my ($curproc) = @_;

    return( $curproc->{ __print_style } || 'text');
}


# Descriptions: set print style
#    Arguments: OBJ($curproc) STR($mode)
# Side Effects: none
# Return Value: STR
sub set_print_style
{
    my ($curproc, $mode) = @_;

    $curproc->{ __print_style } = $mode;
}


=head2 hints()

return hints as HASH_REF.
It is useful to switch process behabiour based on this hints.
This function is used in CGI processes typically to verify
whether the current process runs in admin mode or user mode ? et.al.

=cut


# Descriptions: return hints on this process.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: HASH_REF
sub hints
{
    my ($curproc) = @_;
    my $main_cf = $curproc->{ __parent_args }->{ main_cf };

    return $main_cf->{ _hints };
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002,2003 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::Utils first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
