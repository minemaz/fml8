#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: Subject.pm,v 1.4 2001/04/27 04:44:39 fukachan Exp $
#


###                                                   ###
### CAUTION: THE CHARSET OF THIS FILE IS "EUC-JAPAN". ###
###                                                   ###


package Language::Japanese::Subject;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Carp;
use Jcode;

=head1 NAME

Language::Japanese::Subject - Japanese specific handling of a subject

=head1 SYNOPSIS

    use Language::Japanese::Subject;
    $is_reply = Language::Japanese::Subject::is_reply($subject);

=head1 DESCRIPTION

a collection to handle Japanese specific representations which appears
in the subject.

=cut


require Exporter;
@ISA = qw(Exporter);

# XXX we should it in proper way in the future.
# XXX but we import it anyway for further rewriting.
my $CUT_OFF_RERERE_PATTERN = '';
my $CUT_OFF_RERERE_HOOK    = '';


# subjec reply pattern
# apply patch from OGAWA Kunihiko <kuni@edit.ne.jp> 
#            fml-support:7626 7653 07666
#            Re: Re2:   Re[2]:     Re(2):     Re^2:    Re*2:
# i-mode ? (PR fml-help: 00157 by OGAWA Kunihiko)
my $pattern  = 'Re:|Re\d+:|Re\[\d+\]:|Re\(\d+\):|Re\^\d+:|Re\*\d+:|Re>';
   $pattern .= '|(�ֿ�|��|�ң�|�ң�)(\s*:|��)';


=head1 METHODS

=head2 C<new()>

usual constructor.

=head2 C<is_reply($string)>

check whether C<$string> looks like a reply message.
C<$string> is a C<Subject:> of the mail header.
For example, it is like this:

  Re: reply to your messages

=cut


sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


sub is_reply
{
    my ($self, $x) = @_;
    return 0 unless $x;
    &Jcode::convert(\$x, 'euc');
    return ($x =~ /^((\s|(��))*($pattern)\s*)+/ ? 1 : 0);
}


=head2 C<cut_off_reply_tag($subject)>

cut off C<Re:> in the string C<$subject> like C<Re: ... >
within C<Subject:>.

=cut


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
    my ($subject) = @_;
    my ($y, $limit);

    Jcode::convert(\$subject, 'euc');

    if ($CUT_OFF_RERERE_PATTERN) {
	Jcode::convert(\$CUT_OFF_RERERE_PATTERN, 'euc');
    }

    $pattern .= '|' . $CUT_OFF_RERERE_PATTERN if ($CUT_OFF_RERERE_PATTERN);

    # fixed by OGAWA Kunihiko <kuni@edit.ne.jp> (fml-support: 07815)
    # $subject =~ s/^((\s*|(��)*)*($pattern)\s*)+/Re: /oi;
    $subject =~ s/^((\s|(��))*($pattern)\s*)+/Re: /oi;

    if ($CUT_OFF_RERERE_HOOK) { 
	eval($CUT_OFF_RERERE_HOOK);
	&Log($@) if $@;
    }

    Jcode::convert(\$subject, 'jis');
    $subject;
}


=head1 AUTHOR

 Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

Language::Japanese::Subject appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;