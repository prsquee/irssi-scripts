# google search
# http://search.cpan.org/~manwar/WWW-Google-CustomSearch-0.04/lib/WWW/Google/CustomSearch.pm
#
use strict;
use warnings;
use Irssi qw( signal_add print settings_add_str settings_get_str) ;
use Encode qw(decode);
use URI::Encode qw(uri_encode uri_decode);
use Data::Dumper;
use WWW::Google::CustomSearch;

settings_add_str('gsearch', 'search_apikey', '');
settings_add_str('gsearch', 'engine_id', '' );
signal_add("google me","do_google");

my $engine = WWW::Google::CustomSearch->new(
  api_key => settings_get_str('search_apikey'),
  cx      => settings_get_str('engine_id'),
  alt     => 'json',
  num     => 4
);

sub do_google {
  my ($server, $chan, $query) = @_;
  my $json = $engine->search( uri_encode($query) );

  if (scalar @{ $json->{'items'} } > 0) {
    foreach my $items (@{$json->items}) {
      sayit($server, $chan,"[gugl] $items->{'link'} - " . decode("utf8", $items->{'title'}));
    }
  } else {
    sayit($server,$chan,"found nothin'");
    return;
  }
}
sub sayit { my $s = shift; $s->command("MSG @_"); }
