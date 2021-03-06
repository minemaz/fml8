#-*- perl -*-
#
#  Copyright (C) 2005,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Moderate.pm,v 1.5 2006/05/04 05:34:57 fukachan Exp $
#

package FML::Moderate;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

my $moderation_queue = "submitted";

=head1 NAME

FML::Moderate - manipulate Moderation database.

=head1 SYNOPSIS

use FML::Moderate;
my $moderation = new FML::Moderate $curproc;
$curproc->log("distribute article qid=$queue_id");
$moderation->distribute_article($queue_id);

=head1 DESCRIPTION

This class manipulates moderation database. 

=head1 METHODS

=head2 new($curproc)

constructor

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self) OBJ($curproc)
# Side Effects: none.
# Return Value: OBJ
sub new
{
    my ($self, $curproc) = @_;
    my ($type) = ref($self) || $self;
    my $me     = { _curproc => $curproc };
    return bless $me, $type;
}


=head2 forward_to_moderator

forward incoming message to moderator.

=cut


# Descriptions: forward incoming message to moderator.
#    Arguments: OBJ($self)
# Side Effects: save message in moderation queue.
# Return Value: none
sub forward_to_moderator
{
    my ($self)  = @_;
    my $curproc = $self->{ _curproc };
    my $config  = $curproc->config();
    my $maps    = $config->get_as_array_ref('moderator_recipient_maps');
    my $rm_args = { recipient_maps => $maps };
    my $msg     = $curproc->incoming_message();

    # 1. queue in
    my $queue = $self->_queue_init();
    my $qid   = $queue->id();
    unless ($queue->in( $msg )) {
	$curproc->logerror("moderation request queue-in failed: qid=$qid");
    }
    my $nqid = $queue->dup_content("new", $moderation_queue);
    $queue->remove();
    if ($nqid) {
	$curproc->log("moderation request queue-in: qid=$nqid");
    }

    # 2. generate confirm id.
    $self->_send_confirmation($rm_args, { queue_id => $nqid });

    # 3. forward incoming message.
    $curproc->reply_message($msg, $rm_args);

    # 4. expire
    $queue->expire($moderation_queue);
}


# Descriptions: send moderator confirmation.
#    Arguments: OBJ($self) HASH_REF($rm_args) HASH_REF($opts)
# Side Effects: update database.
# Return Value: none
sub _send_confirmation
{
    my ($self, $rm_args, $opts) = @_;
    my $curproc   = $self->{ _curproc };
    my $config    = $curproc->config();
    my $cache_dir = $config->{ db_dir };
    my $keyword   = $config->{ confirm_command_prefix };
    my $command   = 'moderate';
    my $class     = 'moderate';
    my $cred      = $curproc->credential();
    my $address   = $cred->sender();
    my $queue_id  = $opts->{ queue_id } || '';
    my $default   = "send back the following confirmation.";

    $curproc->log("new moderation request, try confirmation");
    use FML::Confirm;
    my $confirm = new FML::Confirm $curproc, {
            keyword   => $keyword,
            cache_dir => $cache_dir,
            class     => $class,
            address   => $address,
            buffer    => $command,
        };
    my $id = $confirm->assign_id;
    $curproc->reply_message_nl('command.confirm', $default, $rm_args);
    $curproc->reply_message("\n$id\n", $rm_args);

    # save queue id.
    my $mid = $confirm->id();
    $confirm->set($mid, "queue_id", $queue_id);
}


# Descriptions: initialize queue object.
#    Arguments: OBJ($self) STR($qid)
# Side Effects: none
# Return Value: OBJ
sub _queue_init
{
    my ($self, $qid) = @_;
    my $curproc      = $self->{ _curproc };
    my $config       = $curproc->config();
    my $queue_dir    = $config->{ moderate_queue_dir };
    my $expire_limit = $config->as_second('moderate_queue_expire_limit');

    use Mail::Delivery::Queue;
    if ($qid) {
	return new Mail::Delivery::Queue {
	    directory    => $queue_dir,
	    local_class  => [ $moderation_queue ],
	    id           => $qid,
	    expire_limit => $expire_limit,
	};
    }
    else {
	return new Mail::Delivery::Queue {
	    directory    => $queue_dir,
	    local_class  => [ $moderation_queue ],
	    expire_limit => $expire_limit,
	};
    }
}


=head1 DISTRIBUTE ARTICLES

=head2 distribute_article($mid)

distribute article holded in the moderation queue.

=cut


# Descriptions: distribute article.
#    Arguments: OBJ($self) STR($qid)
# Side Effects: do another process.
# Return Value: none
sub distribute_article
{
    my ($self, $qid) = @_;
    my $curproc   = $self->{ _curproc };
    my $config    = $curproc->config();
    my $q_class   = $moderation_queue;
    my $myname    = "distribute";
    my $ml_name   = $config->{ ml_name };
    my $ml_domain = $config->{ ml_domain };

    my $queue = $self->_queue_init($qid);
    if (defined $queue) {
	eval q{
	    close(STDIN);
	    unless ($queue->open($q_class, { in_channel => *STDIN{IO} })) {
		my $qid = $queue->id();
		$curproc->logerror("cannot open qid=$qid");
	    }

	    $curproc->log("emulate $myname for $ml_name\@$ml_domain ML");

	    my $hints = {
		config_overload => {
		    'article_post_restrictions'           => 'permit_anyone',
		    'use_incoming_mail_header_loop_check' => 'no',
		},
	    };

	    eval q{
		use FML::Process::Switch;
		&FML::Process::Switch::NewProcess($curproc,
						  $myname,
						  $ml_name,
						  $ml_domain,
						  $hints);
	    };

	    unless ($@) {
		# remove submitted moderation queue if distribution succeeded.
		$curproc->incoming_message_stack_queue_for_removal($queue);
	    }
	    else {
		$curproc->logerror($@);
	    }

	    $curproc->log("emulation done");
	};
	if ($@) {
	    $curproc->logerror($@);
	}

	# expire
	$queue->expire($moderation_queue);
    }
    else {
	$curproc->logerror("moderate: queue undefined.");
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2005,2006 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Moderate first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
