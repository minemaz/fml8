#-*- perl -*-
#
#  Copyright (C) 2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: External.pm,v 1.2 2004/05/25 16:11:32 fukachan Exp $
#

package FML::Filter::External;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use ErrorStatus qw(error_set error error_clear);

=head1 NAME

FML::Filter::External - spawn external checker program. 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 C<new()>

constructor.

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self) OBJ($curproc)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, $curproc) = @_;
    my ($type) = ref($self) || $self;
    my $me     = { _curproc => $curproc };
    return bless $me, $type;
}


# Descriptions: spawn external driver e.g. virus checker, spam checker.
#    Arguments: OBJ($self) OBJ($curproc) OBJ($msg) STR($driver)
# Side Effects: none
# Return Value: none
sub spawn
{
    my ($self, $curproc, $msg, $driver) = @_;
    my $timeout = 120;
    my $id      = sprintf("%s-%s", time, $$);

    my $_driver = sprintf("%s::%s", "FML::Filter::External", $driver);
    eval qq{
        local(\$SIG{ALRM}) = sub { croak(\"\$id timeout\");};
        alarm( \$timeout );

	use $_driver;
	my \$ext_filter = new $_driver;
	\$ext_filter->process(\$curproc, \$msg);
    };

    # XXX-TODO: exit(75) if timeout.
    my $r;
    if ($r = $@) {
	$curproc->logerror($@);
	if ($r =~ /$id timeout/) {
	    $curproc->logwarn("$driver timeout.");
	}
	else {
	    $self->error_set($@);
	}
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Filter::External appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
