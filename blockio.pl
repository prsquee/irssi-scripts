#bitcoins 
#https://block.io/api
use Irssi qw(signal_add print settings_get_str settings_add_str) ;
use strict;
use warnings;
use JSON;
use LWP::UserAgent;
use Data::Dumper;
 
signal_add('gold digger','check_bitcoins');
settings_add_str('bot config', 'bitcoin_apikey', '');

my $json = new JSON;
my $ua  = LWP::UserAgent->new(timeout => 15);

my $prices_ref   = undef;
my $buffered_for = 1800;  #30m
my $last_fetch   = 0;

my $api_key = settings_get_str('bitcoin_apikey');
my $price_base = 'USD';

my $apiurl = 'https://block.io/api/v1/get_current_price/?'
           . "api_key=$api_key"
           . '&'
           . "price_base=$price_base";

sub check_bitcoins {
  my ($server, $chan) = @_;
  my $output = undef;

  $prices_ref = fetch_prices() if (time - $last_fetch > $buffered_for);

  if ($prices_ref) {
    foreach my $price (@{$prices_ref}) {
      #print (CRAP $price->{'exchange'});
      $output .= "[$price->{'exchange'}] "
              . '$'
              . sprintf("%.2f", $price->{'price'})
              . ' :: ';
    }
    sayit ($server, $chan, $output);
  }
  else {
    sayit ($server, $chan, "sorry, cant check prices now.");
    return;
  }
}

sub fetch_prices {
  $ua->agent(settings_get_str('myUserAgent'));
  my $raw_results = $ua->get($apiurl)->decoded_content;
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

