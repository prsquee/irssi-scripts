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
my $bufferme   = '1';  #10mins
my $json = JSON->new();
my $dolarya_url = 'https://criptoya.com/api/dolar';
my $types = {
  'oficial'   => "[Oficial] ",
  'blue'      => "[Blue] ",
  'mep'       => "[MEP] ",
  'ccl'       => "[CCL] ",
  'ccb'       => "[Cripto] ",
  'solidario' => "[Tarjeta/Ahorro/Qatar] ",
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

  foreach my $key (sort keys %{$types}) {
    my $evalme = ($coin =~ /^dol/) ? "$prices->{$key} * $thismuch" : "$thismuch / $prices->{$key}" ;
    $out = $out . $types->{$key} . '$' . add_dots(int(eval($evalme))) . ' :: ';
  }
  sayit($server, $chan, substr($out, 0, -4));
}
#}}}
sub add_dots {
  my $n = scalar reverse shift;
  $n =~ s/(\d{3})(?=\d)/$1./g if $n =~ /^\d{5,}$/;
  return scalar reverse $n;
}
#{{{ signal and stuff
sub sayit { my $s = shift; $s->command("MSG @_"); }
signal_add("showme the usd","do_dolarya");
#}}}
