#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Kernel.pm,v 1.13 2002/01/30 15:20:30 fukachan Exp $
#

package FML::Process::CGI::Kernel;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use File::Spec;

use FML::Process::Kernel;
use FML::Log qw(Log LogWarn LogError);
@ISA = qw(FML::Process::Kernel);

# load standard CGI routines
use CGI qw/:standard/;


=head1 NAME

FML::Process::CGI::Kernel - CGI basic functions

=head1 SYNOPSIS

   use FML::Process::CGI::Kernel;
   my $obj = new FML::Process::CGI::Kernel;
   $obj->prepare($args);
      ... snip ...

This new() creates CGI object which wraps C<FML::Process::Kernel>.

=head1 DESCRIPTION

the base class of CGI programs.
It provides basic functions and flow.

=head1 METHODS

=head2 C<new()>

ordinary constructor which is used widely in FML::Process classes.

=cut


# Descriptions: constructor.
#               now we re-evaluate $ml_home_dir and @cf again.
#               but we need the mechanism to re-evaluate $args passed from
#               libexec/loader.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, $args) = @_;
    my $type = ref($self) || $self;
    my $is_need_ml_name = $args->{ 'need_ml_name' };

    # we should get $ml_name from HTTP.
    if ($is_need_ml_name) {
	my $ml_home_prefix = $args->{ ml_home_prefix };
	my $ml_name        = safe_param_ml_name($self) || do {
	    croak("not get ml_name from HTTP") if $args->{ need_ml_name };
	};

	use File::Spec;
	my $ml_home_dir = File::Spec->catfile($ml_home_prefix, $ml_name);
	my $config_cf   = File::Spec->catfile($ml_home_dir, 'config.cf');

	# fix $args { cf_list, ml_home_dir };
	my $cflist = $args->{ cf_list };
	push(@$cflist, $config_cf);
	$args->{ ml_home_dir } =  $ml_home_dir;
    }

    # o.k. load configurations
    my $curproc = new FML::Process::Kernel $args;
    return bless $curproc, $type;
}


=head2 C<prepare()>

print HTTP header.
The charset is C<euc-jp> by default.

=cut


# Descriptions: html header.
#               FML::Process::Kernel::prepare() parses incoming_message
#               CGI do not parse incoming_message;
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub prepare
{
    my ($curproc) = @_;
    my $config    = $curproc->{ config };
    my $charset   = $config->{ cgi_charset } || 'euc-jp';

    print header(-type    => "text/html; charset=$charset",
		 -charset => $charset,
		 -target  => "_top");
}


=head2 C<verify_request()>

dummy method now.

=head2 C<finish()>

dummy method now.

=cut

sub verify_request { 1;}

sub finish { 1;}


=head2 C<run()>

dispatch *.cgi programs.

FML::CGI::XXX module should implement these routines:
star_html(), run_cgi() and end_html().

run() executes

    $curproc->start_html($args);
    $curproc->run_cgi($args);
    $curproc->end_html($args);

=cut


# Descriptions: run FML::CGI::* methods
#                  html_start()
#                  run_cgi()
#                  html_end()
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub run
{
    my ($curproc, $args) = @_;

    $curproc->html_start($args);
    $curproc->run_cgi($args);
    $curproc->html_end($args);
}


=head2 get_ml_list($args)

get HASH ARRAY of valid mailing lists.

=cut


# Descriptions: list up ML
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: HASH_ARRAY
sub get_ml_list
{
    my ($curproc, $args) = @_;
    my $config = $curproc->{ config };

    use File::Spec;
    my $cf = '';

    use DirHandle;
    my $dh = new DirHandle $config->{ ml_home_prefix };
    my @dirlist;
    my $prefix = $config->{ ml_home_prefix };
    while ($_ = $dh->read()) {
	next if /^\./;
	next if /^\@/;
	$cf = File::Spec->catfile($prefix, $_, "config.cf");
	push(@dirlist, $_) if -f $cf;
    }
    $dh->close;

    return \@dirlist;
}


=head2 safe_param_xxx()

get and filter param('xxx') via AUTOLOAD().

=cut


# Descriptions: trap safe_param_XXX()
#    Arguments: OBJ($curproc)
# Side Effects: callback to safe_param*().
# Return Value: depend on safe_param*() return value
sub AUTOLOAD
{
    my ($curproc) = @_;

    return if $AUTOLOAD =~ /DESTROY/;

    my $comname = $AUTOLOAD;
    $comname =~ s/.*:://;

    if ($comname =~ /^(safe_paramlist)(\d+)_(\S+)/) {
        my ($method, $numregexp, $varname) = ($1, $2, $3);
        return $curproc->$method($numregexp, $varname);
    }
    elsif ($comname =~ /^(safe_param)_(\S+)/) {
        my ($method, $varname) = ($1, $2);
        return $curproc->$method($varname);
    }
    else {
        croak("unknown method $comname");
    }
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::CGI::Kernel appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
