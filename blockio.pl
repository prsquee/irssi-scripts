#bitcoins and litecoins
#https://block.io/api
#TODO make this pretty
use Irssi qw(signal_add print settings_get_str settings_add_str) ;
use strict;
use warnings;
use JSON;
use LWP::UserAgent;
use Data::Dumper;
 
signal_add('gold digger', 'check_coins');
signal_add('silver digger', 'check_coins');
settings_add_str('bot config', 'ltc_apikey', '');
settings_add_str('bot config', 'btc_apikey', '');

my $json = new JSON;
my $ua  = LWP::UserAgent->new(timeout => 15);

my $prices_ref   = undef;
my $buffered_for = 1800;  #30m

#this should be a hash
my $btc_ref = undef;
my $ltc_ref = undef;
my $last_btc_fetch   = 0;
my $last_ltc_fetch   = 0;

sub check_coins {
  my ($server, $chan, $coin) = @_;
  my $prices_ref = undef;
  if ($coin eq 'btc') {
    $btc_ref = fetch_prices($coin) if (time - $last_btc_fetch > $buffered_for);
    send_out($server, $chan, $btc_ref) if ($btc_ref);
  } 
  elsif ($coin eq 'ltc') {
    $ltc_ref = fetch_prices($coin) if (time - $last_ltc_fetch > $buffered_for);
    send_out($server, $chan, $ltc_ref) if ($ltc_ref);
  }
}
sub send_out {
  my ($server, $chan, $prices_ref) = @_;
  my $output = undef;
  foreach my $price (@{$prices_ref}) {
    #print (CRAP $price->{'exchange'});
    $output .= "[$price->{'exchange'}] "
    . '$'
    . sprintf("%.2f", $price->{'price'})
    . ' :: ';
  }
  sayit($server, $chan, $output);
#  else {
#    sayit ($server, $chan, "sorry, cant check prices now.");
#    return;
#  }
}
sub fetch_prices {
  my $coin        = shift;
  my $api_key     = settings_get_str($coin . '_apikey');
  my $price_base  = 'USD';

  my $apiurl = 'https://block.io/api/v1/get_current_price/?'
           . "api_key=$api_key"
           . '&'
           . "price_base=$price_base";

  $ua->agent(settings_get_str('myUserAgent'));

  my $raw_results = $ua->get($apiurl)->decoded_content;
  my $decoded_json = $json->utf8->decode($raw_results);
  if ($decoded_json->{'status'} eq 'success') { 
    eval ('$last_' . $coin . '_fetch' = time);
    return $decoded_json->{'data'}->{'prices'};
  } 
  else {
    return undef;
  }
}
sub sayit { my $s = shift; $s->command("MSG @_"); }

