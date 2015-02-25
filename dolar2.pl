#dolar2.pl

use Irssi qw(command_bind signal_add print active_win server_find_tag ) ;
use LWP::UserAgent;
use utf8;
use strict;
use warnings;
use Data::Dumper;

#{{{ init and stuff

my $oficial_compra  = undef;
my $oficial_venta   = undef;
my $blue_compra     = undef;
my $blue_venta      = undef;
my $last_fetch      = 0;
my $bufferme        = '1800';  #30mins
my $lanacion_url    = 'http://contenidos.lanacion.com.ar/json/dolar';

sub get_price {
  my $url = shift;
  my $ua  = LWP::UserAgent->new( timeout => 13 );
  $ua->agent(Irssi::settings_get_str('myUserAgent'));

  my $raw_result = $ua->get($url)->content();
  $raw_result =~ s/,/./g;
  #print (CRAP $raw_result);

  ($oficial_venta, $blue_venta, $oficial_compra, $blue_compra)
    = $raw_result =~ m{ "CasaCambioVentaValue" :"([^"]+)?"\..+\.
                        "InformalVentaValue"   :"([^"]+)?"\.
                        "CasaCambioCompraValue":"([^"]+)?"\.
                        "InformalCompraValue"  :"([^"]+)?"
                      }x;

  $last_fetch
    = time() if ( $oficial_compra and $oficial_venta and
                  $blue_compra    and $blue_venta
                );
}
#}}}

#{{{ do_dolar
sub do_dolar {
  my ($server, $chan, $text) = @_;
  my ($ask, $how_much) = $text =~ /^!(\w+)(\s+\d+(?:\.\d{1,2})?)?/;
  if ($ask eq 'pesos' and not $how_much) {
    sayit($server, $chan, 'how much?');
    return;
  }
  get_price($lanacion_url) if (time() - $last_fetch > $bufferme);

  if ($ask =~ /^dol[oa]r$/) {
    if (!$how_much) {
      my $output = '[Oficial] ';
      $output .= ($oficial_compra and $oficial_venta)
                   ? "$oficial_compra | $oficial_venta "
                   : 'no idea ';

      $output .= ':: [Blue] ';
      $output .= ($blue_compra and $blue_venta)
                   ? "$blue_compra | $blue_venta"
                   : 'no idea';

      sayit($server, $chan, $output);
      return;
    }
    elsif ($how_much > 0) {
      my $pesos = undef;
      $pesos .= ($oficial_compra)
                  ? 'Oficialmente el banco te cambia AR$'
                    . sprintf("%.2f", eval($how_much * $oficial_compra))
                    . '. Comprando con la tarjeta te cobran AR$'
                    . sprintf("%.2f", eval($how_much * $oficial_venta * 1.35))
                    . ' final. Si no sos pobre, te sale AR$'
                    . sprintf("%.2f", eval($how_much * $oficial_venta * 1.20))
                    . ' para comprar dólar ahorro. '
                  : undef;

      $pesos .= ($blue_compra)
                  ? 'En una cueva podés cambiar por AR$'
                    . sprintf("%.2f", eval($how_much * $blue_compra)) . '.'
                  : undef;
      $pesos = $pesos || 'not now hooman, try later.';

      sayit($server, $chan, $pesos) if (!$@);
      return;
    }
  }

  if ($ask eq 'pesos' and $how_much > 0) {
    my $dollars = undef;
    $dollars .= ($oficial_venta)
                  ? 'Oficialmente son u$'
                      . sprintf("%.2f", eval($how_much / $oficial_venta))
                      . '. Podés pagar u$'
                      . sprintf("%.2f", eval($how_much  / ($oficial_venta * 1.35)))
                      . ' de tu tarjeta. '
                      . 'Si AFIP te deja, podés comprar u$'
                      . sprintf("%.2f", eval($how_much / ($oficial_venta* 1.20)))
                      . ' de ahorro. '
                  : undef;

    $dollars .= ($blue_venta)
                  ? 'O En una cueva podés comprar u$'
                      . sprintf("%.2f", eval("$how_much / $blue_venta"))
                      . '. '
                  : undef;

    $dollars = $dollars || 'not now hooman, try later.';

    sayit($server, $chan, $dollars) if (!$@);
    return;
  }
}
#}}}

#{{{ signal and stuff
sub sayit { my $s = shift; $s->command("MSG @_"); }
signal_add("showme the money","do_dolar");
#}}}
