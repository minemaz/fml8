#-*- perl -*-
#
#  Copyright (C) 2002,2003 MURASHITA Takuya
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: off.pm,v 1.8 2003/03/18 10:52:34 fukachan Exp $
#

package FML::Command::User::off;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use FML::Log qw(Log LogWarn LogError);


=head1 NAME

FML::Command::User::off - change delivery mode from real time to digest.

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

change delivery mode from real time to digest
after confirmation succeeds.

=head1 METHODS

=head2 process($curproc, $command_args)

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


# Descriptions: lock channel
#    Arguments: none
# Side Effects: none
# Return Value: STR
sub lock_channel { return 'command_serialize';}


# Descriptions: change delivery mode from real time to digest
#               after confirmation succeeds.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: update database for confirmation.
#               prepare reply message.
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;
    my $config        = $curproc->{ config };

    #
    # XXX-TODO: correct to use primary_*_map for on/off ?
    #
    my $member_map    = $config->{ primary_member_map };
    my $recipient_map = $config->{ primary_recipient_map };
    my $cache_dir     = $config->{ db_dir };
    my $keyword       = $config->{ confirm_command_prefix };
    my $command       = $command_args->{ command };
    my $address       = $curproc->{ credential }->sender();

    # cheap sanity checks
    croak("\$member_map is not specified")    unless $member_map;
    croak("\$recipient_map is not specified") unless $recipient_map;

    use FML::Credential;
    my $cred = new FML::Credential $curproc;

    # if not member, off request is wrong.
    unless ($cred->is_member($address)) {
	$curproc->reply_message_nl('error.not_member');
	LogError("off request from not member");
	croak("off request from not member");
	return;
    }

    # if not recipient, off request is wrong.
    unless ($cred->is_recipient($address)) {
	$curproc->reply_message_nl('error.not_recipient');
	LogError("off request from not recipient");
	croak("off request from not recipient");
    }
    # try confirmation before off
    else {
	Log("off request, try confirmation");

        use FML::Confirm;
	my $confirm = new FML::Confirm {
	    keyword   => $keyword,
	    cache_dir => $cache_dir,
	    class     => 'off',
	    address   => $address,
	    buffer    => $command,
	};
	my $id = $confirm->assign_id;
	$curproc->reply_message_nl('command.confirm');
	$curproc->reply_message("\n$id\n");
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

MURASHITA Takuya

=head1 COPYRIGHT

Copyright (C) 2002,2003 MURASHITA Takuya

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::User::off first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
