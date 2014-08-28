#mercadolibre
#'buying_mode' => 'buy_it_now' || acution
use Irssi qw (signal_add print settings_get_str signal_emit);
use strict;
use warnings;
use LWP::UserAgent;
use Data::Dumper;
use JSON;

my $json = new JSON;
my $ua = new LWP::UserAgent;
my $url = 'https://api.mercadolibre.com/items/';

$ua->timeout(10);

sub fml {
  my ($server,$chan,$mla) = @_;
  $ua->agent(settings_get_str('myUserAgent'));
  my $raw_results = $ua->get($url . $mla)->decoded_content;
  my $parsed_json = eval { $json->utf8->decode($raw_results) };
  return if $@;

  my $condition = uc $parsed_json->{condition};
  my $title     = $parsed_json->{title};
  my $price     = $parsed_json->{price};
  my $currency  = $parsed_json->{currency_id};
  my $howmuch   = $currency . ' $' . $price;
  my $city      = $parsed_json->{seller_address}->{city}->{name};
  my $country   = $parsed_json->{seller_address}->{country}->{id};
  my $sold      = $parsed_json->{sold_quantity};

  my $out = "[$condition] $title :: $howmuch :: Sold: $sold :: $city :: $country";
  sayit($server,$chan,$out);
  signal_emit('write to file',"$out\n") if ($chan =~ /sysarmy|moob/);
  return;
}
sub sayit { my $s = shift; $s->command("MSG @_"); }
signal_add('mercadolibre','fml');
