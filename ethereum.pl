#Kraken https://api.kraken.com/0/public/Ticker?pair=ETHUSD
#Binance https://api.binance.com/api/v1/ticker/24hr?symbol=ETHUSDT
#HitBtc https://api.hitbtc.com//api/1/public/ETHUSD/ticker
#https://poloniex.com/public?command=returnTicker
#https://api.coinmarketcap.com/v1/ticker/ethereum/

use Irssi qw(signal_add print settings_add_str settings_get_str) ;
use strict;
use warnings;
use JSON;
use LWP::UserAgent;
use Data::Dumper;
 
signal_add('ethereum', 'do_eth');

my $json = JSON->new();
my $ua   = LWP::UserAgent->new( timeout => 10 );
my $url  = 'https://api.hitbtc.com//api/1/public/ETHUSD/ticker';

#{{{ do fetch
sub do_eth {
  my ($server, $chan) = @_;
  $ua->agent(settings_get_str('myUserAgent'));
  my $req = $ua->get($url);
  my $decoded_json = eval { $json->utf8->decode($req->decoded_content) };
  #print (CRAP Dumper($decoded_json));
  return if $@;

  my $output = undef;
  if (defined($decoded_json->{high})) {
    $output  = '[ethereum] high: $' . sprintf("%.2f", $decoded_json->{high});
    $output .= ' :: low: $' . sprintf("%.2f", $decoded_json->{low});
    $output .= ' :: volume: ' . int($decoded_json->{volume});
  }
  else {
    sayit ($server, $chan, "can't fetch prices right now.");
    return;
  }
  sayit ($server, $chan, $output) if (defined($output));
}#}}}
sub sayit { my $s = shift; $s->command("MSG @_"); }
