#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: unsubscribe.pm,v 1.13 2002/04/03 11:32:59 fukachan Exp $
#

package FML::Command::Admin::unsubscribe;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


=head1 NAME

FML::Command::Admin::unsubscribe - remove the specified member

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

unsubscribe a new user.

=head1 METHODS

=head2 C<process($curproc, $command_args)>

=cut


# Descriptions: standard constructor
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


# Descriptions: need lock or not
#    Arguments: none
# Side Effects: none
# Return Value: NUM( 1 or 0)
sub need_lock { 1;}


# Descriptions: unsubscribe a new user
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: update $member_map $recipient_map
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;
    my $config        = $curproc->{ config };
    my @member_map    = split(/\s+/, $config->{ member_maps });
    my @recipient_map = split(/\s+/, $config->{ recipient_maps });
    my $options       = $command_args->{ options };
    my $address       = $command_args->{ command_data } || $options->[ 0 ];

    # fundamental check
    croak("address is not specified")         unless defined $address;
    croak("\@member_map is not specified")    unless @member_map;
    croak("\@recipient_map is not specified") unless @recipient_map;

    # FML::Command::UserControl specific parameters
    my $uc_args = {
	address => $address,
	maplist => [ @recipient_map, @member_map ],
    };
    my $r = '';

    eval q{
	use FML::Command::UserControl;
	my $obj = new FML::Command::UserControl;
	$obj->userdel($curproc, $command_args, $uc_args);
    };
    if ($r = $@) {
	croak($r);
    }
}


# Descriptions: show cgi menu for unsubscribe
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: update $member_map $recipient_map
# Return Value: none
sub cgi_menu
{
    my ($self, $curproc, $args, $command_args) = @_;
    my $r = '';

    eval q{
	use FML::CGI::Admin::User;
	my $obj = new FML::CGI::Admin::User;
	$obj->cgi_menu($curproc, $args, $command_args);
    };
    if ($r = $@) {
	croak($r);
    }
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::unsubscribe appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
