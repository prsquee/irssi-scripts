#dolarsi.pl

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
my $bufferme   = '30';  #30mins
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
#{{{ do_dolarsi
sub do_dolarsi {
  my ($server, $chan, $coin, $thismuch) = @_;
  my $out = '';
  my $solidario;

  fetch_price($dolarsi_url) if (time() - $last_fetch > $bufferme);


  foreach my $key (@fetched_prices) {
    my $casa = $key->{'casa'};
    foreach my $type (@types) {
      if ($casa->{'nombre'} eq $type) {
        my $compra =  $casa->{'compra'}; $compra =~ tr/,/./;
        my $venta  =  $casa->{'venta'};  $venta  =~ tr/,/./;

        if ($coin =~ /^dol/) {
          $out = $out . "[$type] \$" . add_dots(int(eval($compra * $thismuch)))
                            . ' - $' . add_dots(int(eval($venta * $thismuch)))
                            . ' :: ';

          $solidario = $venta * 1.65 * $thismuch if $type eq 'Dolar Oficial';
        }
        elsif ($coin =~ /^peso/) {
          $out = $out . "[$type] \$" . add_dots(int(eval($thismuch / $venta))) . ' :: ';
          $solidario = $thismuch / ($venta * 1.65) if $type eq 'Dolar Oficial';
        }
      }
    }
  }
  $out = $out . '[Dolar Solidario ahorro] $' . add_dots(int($solidario));
  sayit($server, $chan, $out);

}
#}}}
sub add_dots {
  my $n = scalar reverse shift;
  $n =~ s/(\d{3})(?=\d)/$1./g if $n =~ /^\d{5,}$/;
  return scalar reverse $n;
}
#{{{ signal and stuff
sub sayit { my $s = shift; $s->command("MSG @_"); }
signal_add("showme the usd","do_dolarsi");
#}}}
