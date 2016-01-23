#bitcoins and litecoins
#https://block.io/api
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

my $json = JSON->new();
my $ua  = LWP::UserAgent->new( timeout => 15 );

my $prices_ref   = undef;
my $buffered_for = 3600;

my %coin_prices = ( 'btc' => undef, 'ltc' => undef, );
my %last_fetch  = ( 'btc' => 0, 'ltc' => 0, );

sub check_coins {
  my ($server, $chan, $coin) = @_;
  #$coin can only be btc or ltc

  if (time - $last_fetch{$coin} > $buffered_for) {
    #cache expired, fetch again.
    $coin_prices{$coin} = fetch_prices_for($coin);
  }
  send_out($server, $chan, $coin_prices{$coin}) if $coin_prices{$coin};
}

sub send_out {
  my ($server, $chan, $prices_ref) = @_;
  my @formatted_prices = ();

  foreach my $price (@{$prices_ref}) {
    next if ($price->{'exchange'} eq 'cryptsy');
    push @formatted_prices, '[' . $price->{'exchange'} . '] '
                                . sprintf('$%.2f', $price->{'price'});
  }
  sayit($server, $chan, join(' :: ', @formatted_prices));
}
sub fetch_prices_for {
  my $coin        = shift;
  my $api_key     = settings_get_str($coin . '_apikey');
  my $price_base  = 'USD';

  my $apiurl = 'https://block.io/api/v1/get_current_price/?'
             . "api_key=$api_key"
             . '&'
             . "price_base=$price_base";

  $ua->agent(settings_get_str('myUserAgent'));

  my $got = $ua->get($apiurl);
  unless ($got->is_success) {
    print (CRAP "blockio not success");
    return;
  }

  my $parsed_json = eval { $json->utf8->decode($got->decoded_content) };
  return if $@;

  if ($parsed_json->{'status'} eq 'success') {
    $last_fetch{$coin} = time;
    return $parsed_json->{'data'}->{'prices'};
  }
  else {
    return undef;
  }
}
sub sayit { my $s = shift; $s->command("MSG @_"); }

