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

$ua->agent(settings_get_str('myUserAgent'));
$ua->timeout(10);

sub fml {
  my ($server,$chan,$mla) = @_;
  my $url = "https://api.mercadolibre.com/items/$mla";
  my $req = $ua->get($url);
  my $result = $json->utf8->decode($req->decoded_content);
  #print (CRAP Dumper($result));

  my $title = $result->{title};
  my $condition = uc $result->{condition};
  my $price = $result->{price};
  my $currency = $result->{currency_id};
  my $howmuch = $currency . ' $' . $price;
  my $city    = $result->{seller_address}->{city}->{name};
  my $pais    = $result->{seller_address}->{country}->{id};
  my $sold    = $result->{sold_quantity};

  my $out = "[$condition] $title - $howmuch - Sold: $sold - $city - $pais";
  sayit($server,$chan,$out);
  signal_emit('write to file',"$out\n") if ($chan =~ /sysarmy|moob/);
  return;
}

sub sayit {
  my ($server, $target, $msg) = @_;
  $server->command("MSG $target $msg");
}
signal_add('mercadolibre','fml');
