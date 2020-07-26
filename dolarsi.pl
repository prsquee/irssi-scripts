#dolar3.plA

use Irssi qw(command_bind signal_add print active_win server_find_tag ) ;
use LWP::UserAgent;
use utf8;
use strict;
use warnings;
use Data::Dumper;
use JSON;

#{{{ init and stuff

my @fetched_prices = ();
my $last_fetch = 0;
my $bufferme   = '10';  #30mins
my $json = JSON->new();
my $dolarsi_url = 'https://www.dolarsi.com/api/api.php?type=valoresprincipales';
my @types = ("Dolar Oficial", "Dolar Blue", "Dolar Bolsa", "Dolar Contado con Liqui");

sub fetch_price {
  my $url = shift;
  my $ua  = LWP::UserAgent->new( timeout => 9 );
  $ua->agent(Irssi::settings_get_str('myUserAgent'));

  my $raw_result = $ua->get($url)->content();
  @fetched_prices = @{ $json->utf8->decode($raw_result) };
  $last_fetch = time() if @fetched_prices;
  #print (CRAP Dumper(@fetched_prices));
}
#}}}
#{{{ do_dolar
sub do_dolarsi {
  my ($server, $chan, $howmuch) = @_;

  fetch_price($dolarsi_url) if (time() - $last_fetch > $bufferme);

  my $output = '';
  my $solidario = '';

  foreach my $key (@fetched_prices) {
    my $casa = $key->{'casa'};
    foreach my $type (@types) {
      if ($casa->{'nombre'} eq $type) {
        my $compra =  $casa->{'compra'}; $compra =~ tr/,/./;
        my $venta  =  $casa->{'venta'};  $venta  =~ tr/,/./;

        $output = $output . "[$type] \$" . sprintf("%.2f", eval($compra * $howmuch))
                                . ' - $' . sprintf("%.2f", eval($venta * $howmuch))
                                . ' :: ';
        $solidario = $venta * 1.3 * $howmuch if $type eq 'Dolar Oficial';
      }
    }
  }
  $output = $output . '[Dolar Solidario] $' . sprintf("%.2f", $solidario);
  sayit($server, $chan, $output);
  return;
}
#}}}
#{{{ signal and stuff
sub sayit { my $s = shift; $s->command("MSG @_"); }
signal_add("showme the usd","do_dolarsi");
#}}}
