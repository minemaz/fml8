sub STR2EUC
{
    my ($str) = @_;

    use Jcode;
    &Jcode::convert(\$str, 'euc');
    return $str;
}


sub show_articles_for_ticket
{
    my ($self, $ticket_id) = @_;
    my $mode      = $self->get_mode || 'text';
    my $config    = $self->{ _config };
    my $spool_dir = $config->{ spool_dir };

    $self->db_open();

    my $articles = $self->{ _hash_table }->{ _articles }->{ $ticket_id };

    print "<B>";
    print "show contents related with ticket_id=$ticket_id\n";
    print "</B>";
    print "<HR>";
    print "<PRE>\n";

    if (defined($articles) && defined($spool_dir) && -d $spool_dir) {
	use FileHandle;

	my $s = '';
	for (split(/\s+/, $articles)) {
	    my $file = File::Spec->catfile($spool_dir, $_);
	    my $fh   = new FileHandle $file;
	    while (defined($_ = $fh->getline())) {
		next if 1 .. /^$/;

		$s = STR2EUC($_);
		$s =~ s/&/&amp;/g;
		$s =~ s/</&lt;/g;
		$s =~ s/>/&gt;/g;
		$s =~ s/\"/&quot;/g;
		print $s;
	    }
	    $fh->close;
	}
    }

    print "</PRE>";

    $self->db_close();
}


sub cgi_top_menu
{
    my ($self) = @_;
    my $config = $self->{ _config };
    my $action = 'fmlticket.cgi';
    my $target = $config->{ ticket_cgi_target_window } || 'TicketCGIWindow';

    use DirHandle;
    my $dh = new DirHandle $config->{ ml_home_prefix };
    my @dirlist;
    my $prefix = $config->{ ml_home_prefix };
    while ($_ = $dh->read()) {
	next if /^\./;
	next if /^\@/;
	push(@dirlist, $_) if -f "$prefix/$_/config.cf";
    }
    $dh->close;

    if ($self->get_mode eq 'html') {
	require 'ctime.pl';
	my $time = ctime(time);
	my $ml_name = $config->{  ml_name };
	print "[$time] the brief summary for \"$ml_name\" ML<BR>";
    }

    use CGI qw/:standard/;
    print start_form(-action=>$action, -target=>$target);
    print "mailing list: ", 
    popup_menu(-name   => 'ml_name', -values => \@dirlist),
    submit(-name => 'go'),
    end_form;
}



# This shows summary on C<$ticket_id> in HTML language.
# It is used in C<FML::CGI::TicketSystem>.
sub _show_ticket_by_html_table
{
    my ($self, $optargs) = @_;
    my $config    = $self->{ _config };
    my $ml_name   = $config->{ ml_name };
    my $spool_dir = $config->{ spool_dir };
    my $action    = 'fmlticket.cgi';
    my $target    = $config->{ ticket_cgi_target_window } || 'TicketCGIWindow';

    # printf($fd $format, 
    #        $date, $age, $status, $tid, $rh->{ _articles }->{ $tid });
    my $format   = $optargs->{ format };
    my $date     = $optargs->{ date };
    my $age      = $optargs->{ age };
    my $status   = $optargs->{ status };
    my $tid      = $optargs->{ tid };
    my $articles = $optargs->{ articles };
    my $aid      = (split(/\s+/, $articles))[0];

    # do nothing if the $ticket_id is unknown.
    return unless $tid;

    # <FORM ACTION=> ..>
    my $xtid = CGI::escape($tid);
    $action  = "${action}?ml_name=${ml_name}";
    $action .= "&ticket_id=$xtid&article_id=$aid";

    print "<TR>\n";
    print "<TD>";
    print "<A HREF=\"$action&action=close\" TARGET=\"$target.close\">";
    print "[close]</A>\n";
    print "<BR>\n";
    print "<A HREF=\"$action&action=show\" TARGET=\"$target.show\">";
    print "[see articles]</A>\n";
    print "<TD>$date\n";
    print "<TD>$age\n";
    print "<TD>$status\n";
    print "<TD>$tid\n";
    print "<TD>";

    $aid = (split(/\s+/, $articles))[0];
    my $buf = $self->_article_summary(File::Spec->catfile($spool_dir, $aid));
    print STR2EUC($buf);
}


=head2 C<run_cgi()>

execute CGI.

=cut

sub run_cgi
{
    my ($self) = @_;
    my $config = $self->{ _config };
    my $title  = $config->{ ticket_cgi_title }   || 'ticket system interface';
    my $color  = $config->{ ticket_cgi_bgcolor } || '#E6E6FA';

    # XXX $ml_name may change by HTTP request
    $config->{ ml_name } = param('ml_name') if param('ml_name');

    # ensure the current mode
    $self->mode('html');

    # load standard CGI routines
    use CGI qw/:standard/;

    # get action parameter via HTTP
    my $action = param('action') || 'list';
    my $ticket_id = param('ticket_id');

    # o.k start html
    print start_html(-title=>$title,-BGCOLOR=>$color), "\n";

    if ($action eq 'close') {
	$self->set_status({
	    ticket_id => $ticket_id,
	    status    => 'closed',
	});
    }

    if ($action eq 'show') {
	Log("run.cgi.show_articles for $ticket_id");
	$self->show_articles_for_ticket($ticket_id);
    }
    else {
	# menu at the top of scrren
	$self->cgi_top_menu();

	# show summary
	$self->show_summary();
    }

    # o.k. end of html
    print end_html;
    print "\n";
}


1;