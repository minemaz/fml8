#-*- perl -*-
#
#  Copyright (C) 2002,2003,2004,2005,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Analyze.pm,v 1.33 2006/02/15 13:44:04 fukachan Exp $
#

package FML::Error::Analyze;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


my $debug = 1;


=head1 NAME

FML::Error::Analyze - dispatch model specific analyzer routines.

=head1 SYNOPSIS

    use FML::Error::Cache;
    my $cache = new FML::Error::Cache $curproc;
    my $rdata = $cache->get_all_values_as_hash_ref();

    # $rdata format = {
    #             key1 => [ value1, value2, ... ],
    #             key2 => [ value1, value2, ... ],
    #          }
    use FML::Error::Analyze;
    my $analyzer = new FML::Error::Analyze $curproc;
    $analyzer->$evaluator_function($curproc, $rdata);


=head1 DESCRIPTION

This class provides a top level dispatcher for
model specific analyzer routines.

=head1 METHODS

=head2 new()

constructor.

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self) HASH_REF($curproc)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, $curproc) = @_;
    my ($type) = ref($self) || $self;
    my $me     = { _curproc => $curproc };
    return bless $me, $type;
}


=head1 METHODS

=head2 get_summary()

return summary of address and points as HASH_REF.

    $summary = {
	address1 => point1,
	address2 => point2,
    };

=head2 get_address_to_be_deleted()

return addresses to be removed.

=cut


# Descriptions: return summary as HASH_REF.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: HASH_REF
sub get_summary
{
    my ($self)   = @_;
    my $analyzer = $self->{ _analyzer };

    if (defined $analyzer) {
	return $analyzer->get_summary();
    }
    else {
	return {};
    }
}


# Descriptions: return removal address candidates as HASH_REF.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: ARRAY_REF
sub get_address_to_be_deleted
{
    my ($self)   = @_;
    my $analyzer = $self->{ _analyzer };

    if (defined $analyzer) {
	return $analyzer->get_address_to_be_deleted();
    }
    else {
	return [];
    }
}


=head2 print()

print address and the status summary.

=cut


# Descriptions: print address and the status summary.
#    Arguments: OBJ($self) STR($addr)
# Side Effects: none
# Return Value: none
sub print
{
    my ($self, $addr) = @_;
    my $analyzer      = $self->{ _analyzer };

    if (defined $analyzer) {
	return $analyzer->print($addr);
    }
}


=head2 AUTOLOAD()

the command dispatcher kicking up FML::Error::Analyze::COMMAND class.

=cut


# Descriptions: run FML::Error::Analyze::XXX().
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($anal_data)
# Side Effects: load appropriate module
# Return Value: none
sub AUTOLOAD
{
    my ($self, $curproc, $anal_data) = @_;

    # we need to ignore DESTROY()
    return if $AUTOLOAD =~ /DESTROY/;

    my $fp = $AUTOLOAD;
    $fp =~ s/.*:://;
    my $pkg = "FML::Error::Analyze::${fp}";

    $curproc->logdebug("load $pkg");

    my $analyzer = undef;
    eval qq{ use $pkg; \$analyzer = new $pkg;};
    unless ($@) {
	# run the actual process
	if ($analyzer->can('process')) {
	    $analyzer->process($curproc, $anal_data);
	    $self->{ _analyzer } = $analyzer; # saved for further reference.
	}
	else {
	    $curproc->logerror("${pkg} has no process method");
	}
    }
    else {
	$curproc->logerror($@) if $@;
	$curproc->logerror("$pkg module is not found");
	croak("$pkg module is not found"); # upcall to FML::Error
    }
}


=head1 $data STRUCTURE

C<$data> is passed to the error analyer function
C<FML::Error::Analyze::${fp}> (as $anal_data in AUTOLOAD()).

	 $data = {
	    address => [
	           error_info_1,
	           error_info_2, ...
	    ]
	 };

where the error_info_* has error reasons (STR). $fp parses it, count
up. FML::Error or FML::Error::Analyze can retrieve the result via
get_summary() method.

=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002,2003,2004,2005,2006 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Error::Analyze first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
