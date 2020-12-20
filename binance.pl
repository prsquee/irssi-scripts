# binance public ticker
use Irssi qw(signal_add print settings_get_str settings_add_str) ;
use strict;
use warnings;
use JSON;
use LWP::UserAgent;
use Data::Dumper;

my $json = JSON->new();
my $ua  = LWP::UserAgent->new( timeout => 5 );
$ua->agent(settings_get_str('myUserAgent'));
my $api = 'https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT';

sub fetch_price {
  my $got = $ua->get($api);
  unless ($got->is_success) {
    print (CRAP "error from binance");
    return;
  }
  my $parsed_json = eval { $json->utf8->decode($got->decoded_content) };
  #print(CRAP Dumper($parsed_json));
  return ${parsed_json}->{'price'};
}
