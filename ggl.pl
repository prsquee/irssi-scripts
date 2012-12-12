#ggl.pl
use Irssi qw(signal_add print) ;
use WWW::Shorten::Googl qw( makeshorterlink );
use strict;
use warnings;

sub do_shortme {
	my $url = shift;
	return if ($url !~ m{^https?://\w+.*$}i);
	my $shorten = makeashorterlink($url);
	return $shorten if ($shorten);
}
