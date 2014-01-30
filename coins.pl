#coins #http://www.cryptocoincharts.info/v2/api/tradingPair/coin1_coin2

use Irssi qw(signal_add print settings_add_str settings_get_str) ;
use strict;
use warnings;
use JSON;
use LWP::UserAgent;
use Data::Dumper;
 
signal_add('insert coins', 'coins');

my $json = new JSON;

my $url   = 'http://www.cryptocoincharts.info/v2/api/tradingPair/';
my $ua    = new LWP::UserAgent;
$ua->timeout(10);

#{{{ coins
sub coins {
  my ($server, $chan, $pair) = @_;
  $ua->agent(settings_get_str('myUserAgent'));
  my $req = $ua->get($url . $pair);
  my $r = eval { $json->utf8->decode($req->decoded_content) };
  return if $@;
  #print (CRAP Dumper($r));
  my $msg = undef;
  if (defined($r->{id})) {
    $msg = "[$r->{id}] ";
    $msg .= 'price: ' . $r->{price};
  } else { sayit ($server, $chan, "not a pair. see this list: http://www.cryptocoincharts.info/v2"); return; }
  sayit ($server, $chan, $msg) if (defined($msg));
}#}}}
sub sayit { my $s = shift; $s->command("MSG @_"); }
