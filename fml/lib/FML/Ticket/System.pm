#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: System.pm,v 1.26 2001/10/22 14:10:07 fukachan Exp $
#

package FML::Ticket::System;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use ErrorStatus qw(error_set error error_clear);
use FML::Log qw(Log LogWarn LogError);


=head1 NAME

FML::Ticket::System - ticket system core engine

=head1  SYNOPSIS

   use FML::Ticket::Model::minimal_states;
   $ticket = new FML::Ticket::Model::minimal_states;
   $ticket->assign($curproc, $args);
   $ticket->update_cache($curproc, $args);

=head1 DESCRIPTION

the base class of ticket systems.
This module provides basic functions to help sub classes.

=head2 CLASS HIERARCHY

        FML::Ticket::System
                |
                A 
       -------------------
       |                 |
       A                 A
    minimal_states

=head1 METHODS

=head2 C<new()>

constructor.

=cut


# Descriptions: constructor
#    Arguments: $self
# Side Effects: none
# Return Value: object
sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


# Descriptions: set up directory which is taken from 
#               $self->{ _db_dir }
#    Arguments: $self $curproc $args
# Side Effects: create a "_db_dir" directory if needed
# Return Value: 1 (success) or undef (fail)
sub _init_ticket_db_dir
{
    my ($self, $curproc, $args) = @_;
    my $config = $curproc->{ config };

    if (defined $self->{ _db_dir }) {
	my $db_dir    = $self->{ _db_dir };
	unless (-d $db_dir) {
	    use File::Utils qw(mkdirhier);
	    mkdirhier($db_dir, $config->{ default_directory_mode }) || do {
		$self->error_set( File::Utils->error() );
		return undef;
	    };
	}
    }

    return 1;
}


=head2 C<increment_id(file)>

increment ticket number which is taken up from C<file> 
and save its new number to C<file>.

=cut


# Descriptions: increment ticket number $id holded in $seq_file
#    Arguments: $self $seq_file
# Side Effects: increment id holded in $seq_file 
# Return Value: number
sub increment_id
{
    my ($self, $seq_file) = @_;

    use File::Sequence;
    my $sfh = new File::Sequence { sequence_file => $seq_file };
    my $id  = $sfh->increment_id;
    $self->error_set( $sfh->error );

    $id;
}


=head1 REFERENCES

=head2 ticket status ("RT" case)
                
A Request will always be in one of the following four states:

     Open -- the Request is expecting imminent action a/o updates
  Stalled -- the Request needs a specific action or piece of
             information before it can proceed
 Resolved -- the Request has either been answered or successfully
             taken care of, and no longer needs action
     Dead -- the request should not have been in the ticketing system to begin
             with and has been completely purged.

=head2 ticket status ("REQ" case)

       Another somewhat hardcoded features is the "status" field.
       We're not exactly sure how to use this yet,  but  normally
       use  "stalled" to indicate that this request isn't one can
       make any progress at the moment, thus isn't worth  picking
       from the queue to work on.


=head1 SEE ALSO

L<File::Utils>,
L<File::Sequence>.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::Ticket::System appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
