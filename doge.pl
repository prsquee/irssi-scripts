#WOW SUCH SCRIPT
#https://www.dogeapi.com/api_documentation

use Irssi qw(signal_add print settings_add_str settings_get_str) ;
use strict;
use warnings;
use JSON;
use LWP::UserAgent;
use Data::Dumper;
 
settings_add_str('bitcoin', 'doge_api',    '');
signal_add('such signal','doge');

my $buffer = 1800;
my $fetched = undef;
my $json = new JSON;

#mtgox
my $doge = undef;
my $url   = 'https://www.dogeapi.com/wow/?api_key=';
my $getprice = '&a=get_current_price';
my $ua    = new LWP::UserAgent;
$ua->timeout(15);

#{{{ WOW SUCH SUB
sub doge {
  my ($server, $chan) = @_;
  my $t = defined($doge) ? $fetched : 0;
  if (time - $t > $buffer) {
    $ua->agent(settings_get_str('myUserAgent'));
    my $req = eval { $ua->get($url . $getprice) };
    return if $@;
    my $dogeprice = $req->decoded_content;
    if (defined($dogeprice)) {
      sayit ($server, $chan, "wow. such price: \$$dogeprice");
      $fetched = time();
    } else { $doge = undef; }
  }
}#}}}
sub sayit { my $s = shift; $s->command("MSG @_"); }
