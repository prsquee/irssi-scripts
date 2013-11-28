#bitcoins 
#https://btc-e.com/api/2/btc_usd/ticker

use Irssi qw(signal_add print settings_get_str) ;
use strict;
use warnings;
use JSON;
use LWP::UserAgent;
use Data::Dumper;
 
signal_add('gold digger','btce');

my $buffer = 3600;
my $fetched = undef;
my $json = new JSON;

#btce
my $btce  = undef;
my $url   = 'https://btc-e.com/api/2/btc_usd/ticker';
my $ua    = new LWP::UserAgent;
$ua->agent(settings_get_str('myUserAgent'));
$ua->timeout(15);

#{{{ fetch price
sub btce {
  my ($server, $chan) = @_;
  my $t = defined($btce) ? $fetched : 0;
  if (time - $t > $buffer) {
    my $req = $ua->get($url);
    my $r = $json->utf8->decode($req->decoded_content);
    #print (CRAP Dumper($r));
    if ($r and not $@) {
      #print (CRAP Dumper($r));
      $btce  = '[BTCe] ';
      $btce .= 'sell: $'     . $r->{ticker}{sell}  .' | ';
      $btce .= 'buy: $'      . $r->{ticker}{buy}   .' | ';
      $btce .= 'highest: $'   . $r->{ticker}{high}  .' | ';
      $btce .= 'average: $'  . $r->{ticker}{avg}         ;
      $fetched = time();
    } else { $btce = undef; }
  }
  sayit ($server, $chan, $btce) if (defined($btce));
  return;
}#}}}

sub sayit { #{{{ 
  my ($server, $target, $msg) = @_;
  $server->command("MSG $target $msg");
}#}}}

