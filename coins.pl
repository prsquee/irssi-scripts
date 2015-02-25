#coins #http://www.cryptocoincharts.info/v2/api/tradingPair/coin1_coin2

use Irssi qw(signal_add print settings_add_str settings_get_str) ;
use strict;
use warnings;
use JSON;
use LWP::UserAgent;
use Data::Dumper;
 
signal_add('insert coins', 'coins');

my $json = JSON->new();
my $ua   = LWP::UserAgent->new( timeout => 10 );
my $url  = 'http://www.cryptocoincharts.info/v2/api/tradingPair/';

#{{{ coins
sub coins {
  my ($server, $chan, $pair) = @_;
  $ua->agent(settings_get_str('myUserAgent'));
  my $req = $ua->get($url . $pair);
  my $decoded_json = eval { $json->utf8->decode($req->decoded_content) };
  return if $@;

  my $msg = undef;

  if (defined($decoded_json->{id})) {
    $msg  = "[$decoded_json->{id}] ";
    $msg .= 'price: ' . $decoded_json->{price};
  } 
  else { sayit ($server, $chan, "not a pair. see this list: http://www.cryptocoincharts.info/v2/main/priceBoxes"); return; }

  sayit ($server, $chan, $msg) if (defined($msg));

}#}}}
sub sayit { my $s = shift; $s->command("MSG @_"); }
