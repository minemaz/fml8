#-*- perl -*-
#
#  Copyright (C) 2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: HTMLify.pm,v 1.6 2002/06/27 08:22:21 fukachan Exp $
#

package FML::Command::HTMLify;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use File::Spec;
use FML::Log qw(Log LogWarn LogError);

=head1 NAME

FML::Command::HTMLify - utility functions to convert

=head1 SYNOPSIS

=head1 DESCRIPTION

This module provides several utility functions to send back article
and file in C<$ml_home_dir>.

=head1 METHODS

=cut


# Descriptions:
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects:
# Return Value: none
sub convert
{
    my ($curproc, $args, $optargs) = @_;
    my $src_dir = $optargs->{ src_dir };
    my $dst_dir = $optargs->{ dst_dir };

    croak("src_dir not defined") unless defined $src_dir;
    croak("src_dir not exists")  unless -d $src_dir;
    croak("dst_dir not defined") unless defined $dst_dir;
    croak("dst_dir not exists")  unless -d $dst_dir;

    # XXX NOT NEED THIS CHECK ?
    #     unless ($curproc->is_config_cf_exist()) {
    #		croak("invalid ML");
    #    }

    my ($is_subdir_exists, $subdirs) = _check_subdir_exists($src_dir);
    if ($is_subdir_exists) { Log("looks subdir exists");}

    if (defined $dst_dir) {
        unless (-d $dst_dir) {
            use File::Utils qw(mkdirhier);
            mkdirhier($dst_dir, 0755);
        }

	if ($is_subdir_exists) {
	    my (@x) = sort _sort_subdirs @$subdirs;
	    print STDERR "subdirs; @x \n";
	    for my $xdir (sort _sort_subdirs @$subdirs) {
		eval q{
		    use Mail::Message::ToHTML;
		    &Mail::Message::ToHTML::htmlify_dir($xdir, {
			directory => $dst_dir,
		    });
		};
		croak($@) if $@;
	    }
	}
	else {
	    eval q{
		use Mail::Message::ToHTML;
		&Mail::Message::ToHTML::htmlify_dir($src_dir, {
		    directory => $dst_dir,
		});
	    };
	    croak($@) if $@;
	}
    }
    else {
        croak("no destination directory\n");
    }
}


# Descriptions: sort subdirs by the last dirname
#    Arguments: implicit ($a, $b)
# Side Effects: none
# Return Value: NUM(-1, 0, 1)
sub _sort_subdirs
{
    my ($xa, $xb);

    if ($a =~ /(\d+)$/) { $xa = $1;}
    if ($b =~ /(\d+)$/) { $xb = $1;}

    $xa <=> $xb;
}

# Descriptions: check wheter $src_dir has sub-directories in it
#    Arguments: STR($src_dir)
# Side Effects: none
# Return Value: ARRAY( STR, ARRAY_REF )
sub  _check_subdir_exists
{
    my ($src_dir) = @_;
    my $status = 0;
    my $subdir = '';
    my @subdir = ();

    use File::Spec;
    use DirHandle;
    my $dh = new DirHandle $src_dir;
    if (defined $dh) {
	while (defined($_ = $dh->read)) {
	    next if /^\./;
	    $subdir = File::Spec->catfile($src_dir, $_);

	    if (-d $subdir) {
		push(@subdir, $subdir);
		$status = 1;
	    }
	}
    }

    return( $status, \@subdir );
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::HTMLify appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
