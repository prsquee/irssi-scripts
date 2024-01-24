#mercadolibre
#'buying_mode' => 'buy_it_now' || acution
use Irssi qw (signal_add print settings_get_str signal_emit);
use strict;
use warnings;
use LWP::UserAgent;
use Data::Dumper;
use JSON;

signal_add('mercadolibre','fetch_ml');

my $json = JSON->new();
my $ua   = LWP::UserAgent->new( timeout => '15',
                                ssl_opts => { verify_hostname => 0 }
                              );

my $url = 'https://api.mercadolibre.com/items/';

sub fetch_ml {
  my ($server, $chan, $mla) = @_;
  $ua->agent(settings_get_str('myUserAgent'));
  #my $raw_results = $ua->get($url . $mla)->decoded_content;
  my $req = $ua->get($url . $mla);
  unless ($req->is_success) {
    print (CRAP "mercadolibre error code: $req->code - $req->message");
    return;
  }
  my $parsed_json = eval { $json->utf8->decode($req->decoded_content) };

  my $condition = uc $parsed_json->{condition};
  my $title     = $parsed_json->{title};
  my $price     = $parsed_json->{price};
  my $currency  = $parsed_json->{currency_id};
  my $howmuch   = $currency . ' $' . $price;
  my $city      = $parsed_json->{seller_address}->{city}->{name};
  my $country   = $parsed_json->{seller_address}->{country}->{id};

  my $out = "[$condition] $title :: $howmuch :: $city :: $country";
  sayit($server, $chan, $out);
  return;
}
sub sayit { my $s = shift; $s->command("MSG @_"); }
