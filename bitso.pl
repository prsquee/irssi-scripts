# bitso public ticker
use Irssi qw(signal_add print settings_get_str settings_add_str) ;
use strict;
use warnings;
use JSON;
use LWP::UserAgent;
use Data::Dumper;

my $json = JSON->new();
my $ua  = LWP::UserAgent->new( timeout => 15 );
$ua->agent(settings_get_str('myUserAgent'));
my $api = 'https://api.bitso.com/v3/ticker/?book=btc_usd';

sub fetch_price {
  my $got = $ua->get($api);
  unless ($got->is_success) {
    print (CRAP "error from bitso");
    return;
  }
  my $parsed_json = eval { $json->utf8->decode($got->decoded_content) };
  if ($parsed_json->{'success'}) {
    return $parsed_json->{'payload'}->{'bid'};
  }
}
