#-*- perl -*-
#
#  Copyright (C) 2003 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: mailq.pm,v 1.1 2003/03/14 03:44:16 fukachan Exp $
#

package FML::Command::Admin::mailq;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


=head1 NAME

FML::Command::Admin::mailq - show outgoing mail queue.

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

change delivery mode from real time to digest.

=head1 METHODS

=head2 C<process($curproc, $command_args)>

=cut


# Descriptions: constructor.
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


# Descriptions: change delivery mode from real time to digest.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: update $recipient_map
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;

    $self->_queue($curproc);
}


# Descriptions: open mail queue and list up.
#    Arguments: OBJ($self) OBJ($curproc)
# Side Effects: none
# Return Value: none
sub _queue
{
    my ($self, $curproc) = @_;
    my $config    = $curproc->config();
    my $queue_dir = $config->{ mail_queue_dir };
    my $count     = 0;

    use Mail::Delivery::Queue;
    my $queue = new Mail::Delivery::Queue { directory => $queue_dir };
    my $ra    = $queue->list();

    for my $qid (@$ra) {
	print $qid, "\n";
	$count++;
    }

    unless ($count) {
	print STDERR "Mail queue is empty\n";
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2003 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::mailq first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut

1;