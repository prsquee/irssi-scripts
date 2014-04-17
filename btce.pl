#bitcoins 
#https://btc-e.com/api/2/btc_usd/ticker

use Irssi qw(signal_add print settings_get_str) ;
use strict;
use warnings;
use JSON;
use LWP::UserAgent;
use Data::Dumper;
 
signal_add('gold digger','bitcoin');
signal_add('silver digger','litecoin');

my $wait_for = 3600;
my %time_fetched = ();
my $json = new JSON;

#btce
my %btce  =  ();
my $ua    = new LWP::UserAgent;
$ua->timeout(15);

#{{{ check bitcoin
sub fetch_price {
  my ($server, $chan, $coin) = @_;
  my $last_fetch = defined($btce{$coin}) ? $time_fetched{$coin} : 0;
  if (time - $last_fetch > $wait_for) {
    $ua->agent(settings_get_str('myUserAgent'));
    my $url = "https://btc-e.com/api/2/${coin}_usd/ticker";
    my $ua_got = $ua->get($url);
    my $decoded_json = eval { $json->utf8->decode($ua_got->decoded_content) };
    return if $@;
    if ($decoded_json) {
      $btce{$coin}  = '[BTCe] ';
      $btce{$coin} .= 'sell: $'     . sprintf("%.2f", $decoded_json->{ticker}{sell}) .' | ';
      $btce{$coin} .= 'buy: $'      . sprintf("%.2f", $decoded_json->{ticker}{buy} ) .' | ';
      $btce{$coin} .= 'highest: $'  . sprintf("%.2f", $decoded_json->{ticker}{high}) .' | ';
      $btce{$coin} .= 'average: $'  . sprintf("%.2f", $decoded_json->{ticker}{avg} )       ;
      $time_fetched{$coin} = time();
    } else { $btce{$coin} = undef; }
  }
  sayit ($server, $chan, $btce{$coin}) if (defined($btce{$coin}));
  return;
}#}}}

sub bitcoin   { fetch_price(@_, 'btc'); }
sub litecoin  { fetch_price(@_, 'ltc'); }

sub sayit { my $s = shift; $s->command("MSG @_"); }
