#dolar2.pl

use Irssi qw(command_bind signal_add print active_win server_find_tag ) ;
use LWP::UserAgent;
use strict;
use warnings;
use Data::Dumper;

#{{{ init and stuff

my $oficial_compra  = undef;
my $oficial_venta   = undef;
my $blue_compra     = undef;
my $blue_venta      = undef;
my $pesos           = undef;
my $dollars         = undef;
my $last_fetch      = 0;
my $bufferme        = '1800';  #66mins
my $lanacion_url    = 'http://contenidos.lanacion.com.ar/json/dolar';

sub get_price {
  my $url = shift;
  my $ua  = new LWP::UserAgent;
  $ua->agent(Irssi::settings_get_str('myUserAgent'));
  $ua->timeout(10);

  my $raw_result = $ua->get($url)->content();
  $raw_result =~ s/,/./g;
  #print (CRAP $raw_result);

  ($oficial_venta, $blue_venta, $oficial_compra, $blue_compra)
    = $raw_result =~ m{ "CasaCambioVentaValue" :"([^"]+)?"\..+\.
                        "InformalVentaValue"   :"([^"]+)?"\.
                        "CasaCambioCompraValue":"([^"]+)?"\.
                        "InformalCompraValue"  :"([^"]+)?"
                      }x;

  $last_fetch = time() if ( $oficial_compra and
                            $oficial_venta  and
                            $blue_compra    and
                            $blue_venta
                          );

}
#}}}

#{{{ do_dolar
sub do_dolar {
  my ($server, $chan, $text) = @_;
  my ($ask, $how_much) = $text =~ /^!(\w+)(\s+\d+(?:\.\d{1,2})?)?/; 
  if ($ask eq 'pesos' and not $how_much) {
    sayit($server, $chan, "!pesos <CANTIDAD>");
    return;
  }
  get_price($lanacion_url) if (time() - $last_fetch > $bufferme); 

  my $output = '[Oficial] '; 
  

  $output .= ($oficial_compra and $oficial_venta)
               ? "$oficial_compra | $oficial_venta " 
               : 'no idea ';
 
  $output .= ':: [Blue] ';
  
  $output .= ($blue_compra and $blue_venta)
               ? "$blue_compra | $blue_venta"
               : 'no idea';

  if ($ask =~ /^dol[oa]r$/ and not $how_much) {
    sayit($server, $chan, $output);
    return;
  }
  if ($ask =~ /^dol[oa]r$/ and $how_much > 0) {
    $pesos  = '[Oficial] ';
    $pesos .= ($oficial_compra) ? 'AR$' . eval($how_much * $oficial_compra) 
                                : 'no idea';

    $pesos .= ' :: [Blue] ';
    $pesos .= ($blue_compra) ? 'AR$' . eval($how_much * $blue_compra)
                             : 'no idea';

    $pesos .= ' :: [Tarjeta +35%] ';
    $pesos .= ($oficial_venta) 
                ? 'AR$' . sprintf("%.2f", eval(   $how_much 
                                                * $oficial_venta 
                                                * 1.35
                                              )) 
                : 'no idea';

    $pesos .= ' :: [Ahorro +20%] ';
    $pesos .= ($oficial_venta) 
                ? 'AR$' . sprintf("%.2f", eval(   $how_much 
                                                * $oficial_venta  
                                                * 1.20
                                              ))
                : 'no idea';

    sayit($server, $chan, $pesos) if (!$@);
    return;
  }
  if ($ask eq 'pesos' and $how_much) {
    $dollars = "[Oficial] ";
    $dollars .= ($oficial_venta) 
                  ? 'u$' . sprintf("%.2f", eval($how_much / $oficial_venta)) 
                  : 'no idea';
    $dollars .=  ' :: [Blue] ';
    $dollars .= ($blue_venta) 
                  ? 'u$' . sprintf("%.2f", eval("$how_much / $blue_venta"))
                  : 'no idea';

    sayit($server, $chan, $dollars) if (!$@);
    return;
  }
}
#}}}

#{{{ signal and stuff
sub sayit { my $s = shift; $s->command("MSG @_"); }
signal_add("showme the money","do_dolar");
#}}}
