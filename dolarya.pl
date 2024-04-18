use Irssi qw(command_bind signal_add print active_win server_find_tag ) ;
use LWP::UserAgent;
use utf8;
use strict;
use warnings;
use Data::Dumper;
use JSON;


#{{{ init and stuff

my $prices = '';
my $last_fetch = 0;
my $bufferme   = '300';  #5mins
my $json = JSON->new();
my $dolarya_url = 'https://criptoya.com/api/dolar';
my $types = {
  'oficial'   => "[Oficial] ",
  'blue'      => "[Blue] ",
  'mep'       => "[MEP] ",
  'usdc'       => "[Cripto] ",
  'solidario' => "[Tarjeta/Ahorro] ",
};

sub fetch_price {
  my $url = shift;
  my $ua  = LWP::UserAgent->new( timeout => 9 );
  $ua->agent(Irssi::settings_get_str('myUserAgent'));

  my $raw_result = $ua->get($url)->content();
  $prices = eval { $json->utf8->decode($raw_result) };
  $last_fetch = time() if $prices;
  return $prices;
}
#}}}
#{{{ do_dolarya
sub do_dolarya {
  my ($server, $chan, $coin, $thismuch) = @_;
  my $out = '';

  fetch_price($dolarya_url) if (time() - $last_fetch > $bufferme);

  my $oficial = '[Oficial] $' . (($coin =~ /^dol/) ? in_dolar('oficial', 'price', $thismuch) : in_pesos('oficial', 'price', $thismuch));
  my $tarjeta = '[Tarjeta/Ahorro] $' . (($coin =~ /^dol/) ? in_dolar('tarjeta', 'price', $thismuch) : in_pesos('tarjeta', 'price', $thismuch));
  my $mep = '[MEP] $' . (($coin =~ /^dol/) ? in_dolar('ci', 'price', $thismuch) : in_pesos('ci', 'price', $thismuch));

  my $blue = '[Blue] $' . (($coin =~ /^dol/) ? in_dolar('blue', 'ask', $thismuch) : in_pesos('blue', 'ask', $thismuch)) . '/$'
                        . (($coin =~ /^dol/) ? in_dolar('blue', 'bid', $thismuch) : in_pesos('blue', 'bid', $thismuch));

  my $usdc = '[Cripto] $' . (($coin =~ /^dol/) ? in_dolar('usdc', 'ask', $thismuch) : in_pesos('usdc', 'ask', $thismuch)) . '/$'
                          . (($coin =~ /^dol/) ? in_dolar('usdc', 'bid', $thismuch) : in_pesos('usdc', 'bid', $thismuch));

  sayit($server, $chan, join(' :: ', $oficial, $tarjeta, $blue, $usdc, $mep));
}
#}}}
sub in_dolar {
  my ($k, $p, $n) = @_;
  return add_dots(sprintf("%.0f",  $prices->{$k}->{$p} * $n))                    if exists $prices->{$k};
  return add_dots(sprintf("%.0f",  $prices->{'cripto'}->{$k}->{$p} * $n))        if exists $prices->{'cripto'}->{$k};
  return add_dots(sprintf("%.0f",  $prices->{'mep'}->{'gd30'}->{$k}->{$p} * $n)) if exists $prices->{'mep'}->{'gd30'}->{$k};

}

sub in_pesos {
  my ($k, $p, $n) = @_;
  return add_dots(sprintf("%.0f",  $n / $prices->{$k}->{$p})) if exists $prices->{$k};
  return add_dots(sprintf("%.0f",  $n / $prices->{'cripto'}->{$k}->{$p})) if exists $prices->{'cripto'}->{$k};
  return add_dots(sprintf("%.0f",  $n / $prices->{'mep'}->{'gd30'}->{$k}->{$p})) if exists $prices->{'mep'}->{'gd30'}->{$k};
}


sub add_dots {
  my $n = shift;
  return $n if $n =~ /^\d{4}$/;
  $n =~ s/(?<=\d)(?=(\d{3})+(?!\d))/./g;
  return $n;
}
#{{{ signal and stuff
sub sayit { my $s = shift; $s->command("MSG @_"); }
signal_add("showme the usd","do_dolarya");
#}}}
