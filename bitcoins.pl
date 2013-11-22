#bitcoins 
#https://en.bitcoin.it/wiki/MtGox/API/HTTP/v2
#https://www.bitstamp.net/api/ticker/

use Irssi qw(signal_add print settings_get_str) ;
use strict;
use warnings;
use JSON;
use LWP::UserAgent;
use Data::Dumper;
 
signal_add('gold digger','mtgox');
signal_add('gold finger','bitstamp');

my $buffer = 600;
my %fetched = ();
my $json = new JSON;

#mtgox
my $mtgox       = undef;
my $mtgoxURL    = 'https://data.mtgox.com/api/2/BTCUSD/money/ticker';
my $ua_gox      = new LWP::UserAgent;
$ua_gox->agent(settings_get_str('myUserAgent'));
$ua_gox->timeout(15);

#bitstamp
my $bitstamp    = undef;
my $bitstampURL = 'https://www.bitstamp.net/api/ticker';
my $ua_stamp    = new LWP::UserAgent;
$ua_stamp->agent(settings_get_str('myUserAgent'));
$ua_stamp->timeout(15);


sub bitstamp {
  my ($server, $chan) = @_;
  #if (time - $fetched{$bitstamp} > 60 or not defined($bitstamp)) {
  my $t = defined($bitstamp) ? $fetched{$bitstamp} : 0;
  if (time - $t > $buffer) {
    my $req = $ua_stamp->get($bitstampURL);
    my $r = $json->utf8->decode($req->decoded_content);
    if ($r) {
      $bitstamp  = '[bitstamp] ';
      $bitstamp .= 'high: $' . $r->{high} . ' | ';
      $bitstamp .= 'low: $' .  $r->{low}  . ' | ';
      $bitstamp .= 'average: $' . sprintf("%.2f", eval("($r->{bid} + $r->{ask}) / 2"));
      $fetched{$bitstamp} = time();
    } else { $bitstamp = 'failed to fetch prices from bitstamp'; }
    #print (CRAP Dumper($r)) 
  }
  sayit ($server, $chan, $bitstamp) if (defined($bitstamp));
  return;
}

#{{{ mtgox 
sub mtgox {
  my ($server, $chan) = @_;
  my $t = defined($mtgox) ? $fetched{$mtgox} : 0;
  if (time - $t > $buffer) {
    my $req = $ua_gox->get($mtgoxURL);
    my $r = $json->utf8->decode($req->decoded_content);
    #print (CRAP Dumper($r));
    if ($r->{result} eq 'success') {
      #print (CRAP "MTGOX");
      $mtgox  = '[mtgox] ';
      $mtgox .= 'sell: '     . $r->{data}{sell}{display_short} .' | ';
      $mtgox .= 'buy: '      . $r->{data}{buy}{display_short}  .' | ';
      $mtgox .= 'highest: '  . $r->{data}{high}{display_short} .' | ';
      $mtgox .= 'average: '  . $r->{data}{avg}{display_short};
      $fetched{$mtgox} = time();
    } else { $mtgox = 'failed to fetch prices from mtgox'; }
  }
  sayit ($server, $chan, $mtgox) if (defined($mtgox));
  return;
}#}}}

sub sayit { #{{{ 
  my ($server, $target, $msg) = @_;
  $server->command("MSG $target $msg");
}#}}}

