#bitcoins 
#https://btc-e.com/api/2/btc_usd/ticker
#https://btc-e.com/api/2/ltc_usd/ticker

use Irssi qw(signal_add print settings_get_str) ;
use strict;
use warnings;
use JSON;
use LWP::UserAgent;
use Data::Dumper;
 
signal_add('gold digger','bitcoin');
signal_add('silver digger','litecoin');

my $buffer = 3600;
my %fetched = ();
my $json = new JSON;

#btce
my %btce  =  ();
my $ua    = new LWP::UserAgent;
$ua->agent(settings_get_str('myUserAgent'));
$ua->timeout(15);

#{{{ check bitcoin
sub fetch_price {
  my ($server, $chan, $coin) = @_;
  my $t = defined($btce{$coin}) ? $fetched{$coin} : 0;
  if (time - $t > $buffer) {
    my $url = "https://btc-e.com/api/2/${coin}_usd/ticker";
    my $req = $ua->get($url);
    my $r = $json->utf8->decode($req->decoded_content);
    #print (CRAP Dumper($r));
    if ($r and not $@) {
      #print (CRAP Dumper($r));
      $btce{$coin}  = '[BTCe] ';
      $btce{$coin} .= 'sell: $'     . sprintf("%.2f", $r->{ticker}{sell}) .' | ';
      $btce{$coin} .= 'buy: $'      . sprintf("%.2f", $r->{ticker}{buy} ) .' | ';
      $btce{$coin} .= 'highest: $'  . sprintf("%.2f", $r->{ticker}{high}) .' | ';
      $btce{$coin} .= 'average: $'  . sprintf("%.2f", $r->{ticker}{avg} )       ;
      $fetched{$coin} = time();
    } else { $btce{$coin} = undef; }
  }
  sayit ($server, $chan, $btce{$coin}) if (defined($btce{$coin}));
  return;
}#}}}
#{{{ btc
sub bitcoin {
  my ($server, $chan) = @_;
  fetch_price($server, $chan, 'btc');
  return;
}#}}}
#{{{ ltc
sub litecoin {
  my ($server, $chan) = @_;
  fetch_price($server, $chan, 'ltc');
  return;
}#}}}

sub sayit { #{{{ 
  my ($server, $target, $msg) = @_;
  $server->command("MSG $target $msg");
}#}}}

