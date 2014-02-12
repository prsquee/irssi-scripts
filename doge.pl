#WOW SUCH SCRIPT
#https://www.dogeapi.com/api_documentation

use Irssi qw(signal_add print settings_add_str settings_get_str) ;
use strict;
use warnings;
use JSON;
use LWP::UserAgent;
use Data::Dumper;
 
settings_add_str('bot', 'doge_api',    '');
signal_add('such signal','doge');

my $buffer = 1800;
my $fetched = undef;
my $json = new JSON;

my $doge      = undef;
my $dogeprice = undef;
my $url       = 'https://www.dogeapi.com/wow/?api_key=';
my $getprice  = '&a=get_current_price';
my $ua        = new LWP::UserAgent;

$ua->timeout(15);

#{{{ WOW SUCH SUB
sub doge {
  my ($server, $chan, $text) = @_;
  my ($muchcoins) = $text =~ /!doge(?:\w+)? (\d+)$/;
  my $t = defined($doge) ? $fetched : 0;
  if (time - $t > $buffer) {
    $ua->agent(settings_get_str('myUserAgent'));
    my $req = eval { $ua->get($url . $getprice) };
    return if $@;
    $dogeprice = $req->decoded_content;
    $fetched = time();
  }
  if (defined($dogeprice) and not defined($muchcoins)) {
    sayit($server, $chan, "wow. such price: 1 Ɖ = \$$dogeprice | \$1 = " . sprintf("%.5f", eval("1/$dogeprice")) . ' dogecoins');
  } elsif (defined($muchcoins) and $muchcoins > 0) {
      sayit($server, $chan, "wow. very rich: \$" . sprintf("%.2f", eval("$muchcoins * $dogeprice")));
  } else { $doge = undef; }
}#}}}
sub sayit { my $s = shift; $s->command("MSG @_"); }
