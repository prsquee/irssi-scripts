#bitcoins and litecoins
# https://block.io/api
use Irssi qw(signal_add print settings_get_str settings_add_str) ;
use strict;
use warnings;
use JSON;
use LWP::UserAgent;
use Data::Dumper;
 
signal_add('gold digger',   'check_coins');
signal_add('silver digger', 'check_coins');
signal_add('such signal',   'check_coins');
settings_add_str('bot config', 'ltc_apikey', '');
settings_add_str('bot config', 'btc_apikey', '');
settings_add_str('bot config', 'doge_apikey', '');

my $json = JSON->new();
my $ua  = LWP::UserAgent->new( timeout => 15 );

my $buffered_for = 1800;

my %coin_prices = ( 'btc' => undef, 'ltc' => undef, 'doge' => undef );
my %last_fetch  = ( 'btc' => 0, 'ltc' => 0, 'doge' => 0 );

sub check_coins {
  my ($server, $chan, $coin) = @_;
  #$coin can only be btc, ltc or doge

  if (time - $last_fetch{$coin} > $buffered_for) {
    #cache expired, fetch again.
    $coin_prices{$coin} = fetch_prices_for($coin);
  }
  #send_out($server, $chan, $coin_prices{$coin}) if $coin_prices{$coin};
  send_out($server, $chan, $coin) if $coin_prices{$coin};
}

sub send_out {
  #my ($server, $chan, $prices_ref) = @_;
  my ($server, $chan, $coin) = @_;

  my @formatted_prices = ();

  foreach my $this (@{ $coin_prices{$coin} }) {
    next if ($this->{'exchange'} eq 'cryptsy');
    push @formatted_prices,
          '[' . $this->{'exchange'} . '] '
          . ($coin eq 'doge'
                ? ($coin_prices{'btc'}[0]
                               ? '1 Ð = ' . sprintf('$%.6f', $this->{'price'} * $coin_prices{'btc'}[0]->{'price'})
                               : '1 Ð = ' . $this->{'price'} . ' BTC'
                             )
                : sprintf('$%.2f', $this->{'price'})
             );
  }
  sayit($server, $chan, join(' :: ', @formatted_prices));
}
sub fetch_prices_for {
  my $coin        = shift;
  my $api_key     = settings_get_str($coin . '_apikey');
  my $price_base  = 'USD';
  $price_base     = 'BTC' if $coin eq 'doge';

  my $apiurl = 'https://block.io/api/v2/get_current_price/?'
             . "api_key=${api_key}"
             . "&price_base=${price_base}";

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

