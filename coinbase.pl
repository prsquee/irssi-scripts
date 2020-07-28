# coinbase public api
use Irssi qw(signal_add print settings_add_str settings_get_str);
use strict;
use warnings;
use LWP::UserAgent;
use JSON;
use Data::Dumper;
use DateTime;
use utf8;
use Encode qw (encode decode);

#init
signal_add("gold digger", "fetch_coins");

my $json = JSON->new();
my $api_url = 'https://api.coinbase.com/v2/prices/spot?currency=USD';
my $last_fetch = 0;


sub fetch_coins {
  my ($server, $chan, $howmuch) = @_;
  my $ua  = LWP::UserAgent->new( timeout => 5 );
  $ua->agent(Irssi::settings_get_str('myUserAgent'));

  my $raw = $ua->get($api_url)->content();
  my $coins = $json->utf8->decode($raw);
  my $price = $coins->{'data'}->{'amount'};
  sayit($server,$chan, '[coinbase] $' . sprintf("%.2f", eval($price * $howmuch)));
}
sub sayit { my $s = shift; $s->command("MSG @_"); }
