#WOW SUCH SCRIPT
# http://www.dogeapi.com/api_documentation

use Irssi qw(signal_add print settings_add_str settings_get_str) ;
use strict;
use warnings;
use JSON;
use LWP::UserAgent;
use Data::Dumper;
use utf8;
 
settings_add_str('bot config', 'doge_api', '');
signal_add('such signal','wow');

my $json          = JSON->new();
my $buffered_for  = 1800; #seconds. = 30mins
my $prices_ref    = undef;

my $last_fetch = 0;
my $api_key    = settings_get_str('doge_api');
my $price_base = 'USD';
my $ua         = LWP::UserAgent->new(timeout => '15');

my $apiurl     = 'https://block.io/api/v1/get_current_price/?'
               . "api_key=${api_key}&"
               . "price_base=${price_base}";

#{{{ WOW SUCH SUB
sub wow {
  my ($server, $chan, $text) = @_;
  my ($much_coins) = $text =~ /!doge(?:\w+)? (\d+)$/;
  $prices_ref = fetch_price() if (time - $last_fetch > $buffered_for);
  #print (CRAP Dumper($decoded_json));
  if ($prices_ref) {
    foreach my $price ( @{$prices_ref} ) {
      sayit ($server, $chan, "[$price->{'exchange'}] " 
                             . '1Ɖ = '
                             . $price->{'price'}
                             . ' | '
                             . '$1 = '
                             . sprintf("%.5f", eval("1 / $price->{'price'}"))
                             . ' dogecoins'
            );
    }
  }
}#}}}

sub fetch_price {
  $ua->agent(settings_get_str('myUserAgent'));
  my $raw_results = $ua->get($apiurl)->content;
  #my $decoded_json = $json->utf8->decode($raw_results);
  my $decoded_json = $json->utf8->decode($raw_results);
  if ($decoded_json->{'status'} eq 'success') { 
    $last_fetch = time();
    return $decoded_json->{'data'}->{'prices'};
  } 
  else {
    return undef;
  }
}
sub sayit { my $s = shift; $s->command("MSG @_"); }
