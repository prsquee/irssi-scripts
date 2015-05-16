#ggl.pl
use strict;
use warnings;
use Irssi qw(signal_add print settings_get_str) ;
use WWW::Google::URLShortener;

Irssi::settings_add_str('apikey', 'google_apikey', '');

my $shortener = WWW::Google::URLShortener->new(
    { api_key => settings_get_str('google_apikey') }
);

sub do_shortme {
  my $url = shift;
  my $shorten = $shortener->shorten_url($url);
  return $shorten if ($shorten);
}
