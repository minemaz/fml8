#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: get.pm,v 1.5 2001/10/14 00:32:29 fukachan Exp $
#

package FML::Command::User::get;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

use ErrorStatus;
use FML::Command::Utils;
use FML::Command::SendFile;
use FML::Log qw(Log LogWarn LogError);
@ISA = qw(FML::Command::SendFile FML::Command::Utils ErrorStatus);

=head1 NAME

FML::Command::User::get - send back articles

=head1 SYNOPSIS

not yet implemented

=head1 DESCRIPTION

=head1 METHODS

=head2 C<new()>

=cut


sub process
{
    my ($self, $curproc, $command_args) = @_;
    $self->send_article($curproc, $command_args);
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::User::get appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
