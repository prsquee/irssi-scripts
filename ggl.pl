#ggl.pl
use Irssi qw(signal_add print) ;
use WWW::Shorten::Googl qw( makeshorterlink );
use strict;
use warnings;

sub do_shortme {
  $ENV{'PERL_LWP_SSL_VERIFY_HOSTNAME'} = 0;
  my $url = shift;
  return undef if ($url !~ m{^https?://\w+.*$}i);
  my $shorten = makeashorterlink($url);
  return $shorten if ($shorten);
}
