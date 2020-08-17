# bitfinex public api
use Irssi qw(signal_add print settings_get_str settings_add_str) ;
use strict;
use warnings;
use JSON;
use LWP::UserAgent;
use Data::Dumper;

my $json = JSON->new();
my $ua  = LWP::UserAgent->new( timeout => 15 );
$ua->agent(settings_get_str('myUserAgent'));
my $api = 'https://api-pub.bitfinex.com/v2/ticker/tBTCUSD';

sub fetch_price {
  my $got = $ua->get($api);
  unless ($got->is_success) {
    print (CRAP "error from bitfinex");
    return;
  }
  my $parsed_json = eval { $json->utf8->decode($got->decoded_content) };
  #print(CRAP Dumper($parsed_json));
  return ${$parsed_json}[0];
}

# [
#     BID, 
#     BID_SIZE, 
#     ASK, 
#     ASK_SIZE, 
#     DAILY_CHANGE, 
#     DAILY_CHANGE_RELATIVE, 
#     LAST_PRICE, 
#     VOLUME, 
#     HIGH, 
#     LOW
#   ],
