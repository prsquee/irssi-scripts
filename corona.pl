use Irssi qw(signal_add print settings_add_str settings_get_str);
use strict;
use warnings;
use LWP::UserAgent;
use JSON;
use Data::Dumper;
use WWW::Shorten::TinyURL;
use utf8;

#init
signal_add("coronavirus", "fetch_infected");

my $json = JSON->new();

#my $api_url = 'https://corona-stats.online/Argentina?format=json';
my $api_url = 'https://nicolas17.s3.amazonaws.com/covid-ar.json';
my $last_fetch = 0;

sub fetch_infected {
  my ($server, $chan) = @_;
  my $ua  = LWP::UserAgent->new( timeout => 8 );
  $ua->agent(Irssi::settings_get_str('myUserAgent'));

  my $raw = $ua->get($api_url)->content();
  #print (CRAP Dumper($raw));
  my $fetched = $json->utf8->decode($raw);
  $last_fetch = time() if $fetched;
  my $output = "[Argentina] $fetched->{'cases'} casos confirmados y $fetched->{'deaths'} muertes. Sauce: " . makeashorterlink($fetched->{'source_url'});
  sayit($server, $chan, $output);
}
sub sayit { my $s = shift; $s->command("MSG @_");  }
