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
    my $decoded_content = $ua->get($url)->decoded_content;
    my $decoded_json = eval { $json->utf8->decode($decoded_content) };
    return if $@;
    #print (CRAP Dumper($r));
    (defined($decoded_json->{btc_to_usd}))
      ? $coinbase = '[Coinbase] $' . sprintf("%.2f", $decoded_json->{btc_to_usd})
      : undef;
    $fetched = time();
  }
  sayit ($server, $chan, $coinbase) if (defined($coinbase));
  return;
}#}}}
sub sayit { my $s = shift; $s->command("MSG @_"); }
