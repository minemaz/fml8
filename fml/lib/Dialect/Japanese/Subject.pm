#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

package Dialect::Japanese::Subject;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Carp;
use Jcode;

require Exporter;
@ISA = qw(Exporter);

# XXX we should it in proper way in the future.
# XXX but we import it anyway for further rewriting.
my $CUT_OFF_RERERE_PATTERN;
my $CUT_OFF_RERERE_HOOK;


sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


# fml-support: 07507
# sub CutOffRe
# {
#    ���ޤޤǤɤ���� Re: �Ȥ��ȤäѤ餦 
#
#   if ($LANGUAGE eq 'Japanese') {
#	���ܸ������¸�饤�֥�������
#	������� $CUT_OFF_PATTERN (config.ph)�ʤɤˤ������ä�
#	�ڤ���Ȥ��Τ��ɤ��ʤ��ä����ܸ��񤯤������Ȥ��⤦�櫓��
#	�ǡ����Υ饤�֥�����Ǽ¹Ԥ����
#   }
#
#   run-hooks $CUT_OFF_HOOK(�桼�����HOOK)
#}
# �����к�
sub cut_off_reply_tag
{
    my ($x) = @_;
    my ($y, $limit, $pattern);

    Jcode::convert(\$x, 'euc');

    if ($CUT_OFF_RERERE_PATTERN) {
	Jcode::convert(*CUT_OFF_RERERE_PATTERN, 'euc');
    }

    # apply patch from OGAWA Kunihiko <kuni@edit.ne.jp> 
    #            fml-support:7626 7653 07666
    #            Re: Re2:   Re[2]:     Re(2):     Re^2:    Re*2:
    $pattern  = 'Re:|Re\d+:|Re\[\d+\]:|Re\(\d+\):|Re\^\d+:|Re\*\d+:';
    $pattern .= '|(�ֿ�|��|�ң�|�ң�)(\s*:|��)';
    $pattern .= '|' . $CUT_OFF_RERERE_PATTERN if ($CUT_OFF_RERERE_PATTERN);

    # fixed by OGAWA Kunihiko <kuni@edit.ne.jp> (fml-support: 07815)
    # $x =~ s/^((\s*|(��)*)*($pattern)\s*)+/Re: /oi;
    $x =~ s/^((\s|(��))*($pattern)\s*)+/Re: /oi;

    if ($CUT_OFF_RERERE_HOOK) { 
	eval($CUT_OFF_RERERE_HOOK);
	&Log($@) if $@;
    }

    Jcode::convert(*x, 'jis');
    $x;
}


=head1 NAME

Dialect::Japanese::Subject.pm - what is this


=head1 SYNOPSIS

=head1 DESCRIPTION

=head2 new

=item Function()


=head1 AUTHOR

 Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

Dialect::Japanese::Subject.pm appeared in fml5.

=cut


1;