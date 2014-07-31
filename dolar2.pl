#dolar2.pl

use Irssi qw(command_bind signal_add print active_win server_find_tag ) ;
use LWP::UserAgent;
use strict;
use warnings;
use Data::Dumper;

#{{{ init and stuff

my $oficial_compra  = '0';
my $oficial_venta   = '0';
my $blue_compra     = '0';
my $blue_venta      = '0';
my $last_fetch      = '0';
my $bufferme        = '1800';  #66mins
my $pesos   = undef;
my $dollars = undef;
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
    = $raw_result =~ m{ "CasaCambioVentaValue" :"(\d+(?:\.\d+)?)"\.
                        .+\.
                        "InformalVentaValue"   :"(\d+(?:\.\d+)?)"\.
                        "CasaCambioCompraValue":"(\d+(?:\.\d+)?)"\.
                        "InformalCompraValue"  :"(\d+(?:\.\d+)?)"
                      }x;

  $last_fetch = time() if ( $oficial_compra and 
                            $oficial_venta and 
                            $blue_compra and 
                            $blue_venta 
                          );
}
#}}}

#{{{ do_dolar
sub do_dolar {
  my ($server, $chan, $text) = @_;
  my ($ask, $how_much) = $text =~ /^!(\w+)\s?(\d+(?:\.\d{1,2})?)?/; 
  if ($ask eq 'pesos' and not $how_much) {
    sayit($server, $chan, "!pesos <CANTIDAD>");
    return;
  }
  get_price($lanacion_url) if (time() - $last_fetch > $bufferme); 

  my $output = "[Oficial] $oficial_compra/$oficial_venta | "
             . "[Blue] $blue_compra/$blue_venta";

  if ($ask eq 'dolar' and not $how_much) {
    sayit($server, $chan, $output);
    return;
  }
  if ($ask eq 'dolar' and $how_much > 0) {
    #print_msg("calcular el dolar en pesos");
    $pesos = "[Oficial] "
           . eval("$how_much * $oficial_compra") 
           . " pesos | "
           . "[Tarjeta +35%] " 
           . sprintf("%.2f", eval("$how_much * $oficial_compra * 1.35")) 
           . " pesos | "
           . "[Ahorro +20%] "
           . sprintf("%.2f", eval("$how_much * $oficial_compra * 1.20"))
           . " pesos | "
           . "[Blue] "
           . eval($how_much * $blue_compra) 
           . " pesos";
    sayit($server, $chan, $pesos) if (!$@);
    return;
  }
  if ($ask eq 'pesos' and $how_much) {
    $dollars = "[Oficial] " 
             . sprintf("%.2f", eval("$how_much / $oficial_venta" )) 
             . " | "
             . "[Blue] "
             . sprintf("%.2f", eval("$how_much / $blue_venta"     ));
    sayit($server, $chan, $dollars) if (!$@);
    return;
  }
}
#}}}

#{{{ signal and stuff
sub sayit { my $s = shift; $s->command("MSG @_"); }
signal_add("showme the money","do_dolar");
#}}}
