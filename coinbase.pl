#coinbase

use Irssi qw(signal_add print settings_add_str settings_get_str) ;
use strict;
use warnings;
use JSON;
use LWP::UserAgent;
use Data::Dumper;
 
signal_add('gold digger','coinbase');

my $buffer = 1800;
my $fetched = undef;
my $json = new JSON;

my $coinbase  = undef;
my $url       = 'https://coinbase.com/api/v1/currencies/exchange_rates';
my $ua        = LWP::UserAgent->new(timeout => 15);

#{{{ 
sub coinbase {
  my ($server, $chan) = @_;
  my $t = defined($coinbase) ? $fetched : 0;
  if (time - $t > $buffer) {
    $ua->agent(settings_get_str('myUserAgent'));
    my $req = $ua->get($url);
    my $r = eval { $json->utf8->decode($req->decoded_content) };
    return if $@;
    #print (CRAP Dumper($r));
    $coinbase = '[Coinbase] $' . $r->{btc_to_usd} if (defined($r->{btc_to_usd}));
    $fetched = time();
  }
  sayit ($server, $chan, $coinbase) if (defined($coinbase));
  return;
}#}}}
sub sayit { my $s = shift; $s->command("MSG @_"); }
