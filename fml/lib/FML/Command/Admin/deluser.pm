#-*- perl -*-
#
#  Copyright (C) 2001,2002,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: deluser.pm,v 1.4 2002/12/15 13:46:28 fukachan Exp $
#

package FML::Command::Admin::deluser;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


use FML::Command::Admin::unsubscribe;
@ISA = qw(FML::Command::Admin::unsubscribe);


# Descriptions: remove the specified user.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: forward request to unsubscribe module
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;
    $self->SUPER::process($curproc, $command_args);
}

=head1 NAME

FML::Command::Admin::deluser - remove the specified user

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

all requests are forwarded to C<FML::Command::Admin::unsubscribe>.

=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002,2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::deluser first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;