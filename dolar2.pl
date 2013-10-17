#dolar2.pl
#http://www.eldolarblue.net/getDolarBlue.php?as=json
#http://www.eldolarblue.net/getDolarLibre.php?as=json

use Irssi qw(command_bind signal_add print active_win server_find_tag ) ;
use LWP::UserAgent;
use strict;
use warnings;
use Data::Dumper;
use JSON;

#{{{ init and stuff

my $libreC  = '0';
my $libreV  = '0';
my $blueC   = '0';
my $blueV   = '0';
my $last_fetch = '0';
my $bufferme = '7200';
my $pesos_mugrosos = undef;
my $sweet_dollars = undef;

my $blueURL   = qw( http://www.eldolarblue.net/getDolarBlue.php?as=json );
my $libreURL  = qw( http://www.eldolarblue.net/getDolarLibre.php?as=json );

sub getPrice {
  #initial fetch and they'll stay in ram
  ($blueC, $blueV) = gimmeMoney($blueURL);
  ($libreC, $libreV) = gimmeMoney($libreURL);
  #print (CRAP "blues $blueC and $blueV");
  #print (CRAP "libres $libreC and $libreV");

  #$dateFetched = strftime "%F", localtime if defined($libreC and $libreV and $blueC and $blueV);
  $last_fetch = time() if defined($libreC and $libreV and $blueC and $blueV);
}
#}}}

#{{{ do_dolar
sub do_dolar {
	my ($server,$chan,$text) = @_;
  my ($ask, $how_much) = $text =~ /^!(\w+)\s*(\d*)$/;
  if ($ask eq 'pesos' and not $how_much) {
    sayit($server, $chan, "!pesos <CANTIDAD>");
		return;
  }
  getPrice() if (time() - $last_fetch > $bufferme); 

  my $output = "[Oficial] => $libreC/$libreV | [Blue] => $blueC/$blueV";

	if ($ask eq 'dolar' and not $how_much) {
		sayit($server, $chan, $output);
		return;
	}
	if ($ask eq 'dolar' and $how_much > 0) {
		#print_msg("calcular el dolar en pesos");
		$pesos_mugrosos = "[Oficial] " . eval("$how_much * $libreC")                         . " pesos | ";
    $pesos_mugrosos.= "[Tarjeta] " . sprintf("%.2f", eval("$how_much * $libreC * 1.20")) . " pesos | ";
    $pesos_mugrosos.= "[Blue] "    . eval($how_much * $blueC)                            . " pesos";
		sayit($server, $chan, $pesos_mugrosos) if ($pesos_mugrosos and !$@);
		return;
	}
	if ($ask eq 'pesos' and $how_much) {
    $sweet_dollars = "[Oficial] " . sprintf("%.2f", eval("$how_much / $libreV")) . " | ";
    $sweet_dollars.= "[Blue] "    . sprintf("%.2f", eval("$how_much / $blueV" ));
		sayit($server, $chan, $sweet_dollars) if (defined($sweet_dollars) and !$@);
		return;
	}
}
#}}}

#{{{  fetch prices
sub gimmeMoney {
  my $url = shift;
	my $ua = new LWP::UserAgent;

  $ua->agent(Irssi::settings_get_str('myUserAgent'));
	$ua->max_redirect(1);
	$ua->timeout(10);

	my $req = $ua->get($url);
  my $result = $req->content;
  #print (CRAP $result);
  my ($compra, $venta) = $result =~ m{buy:(\d\.\d{4}),sell:(\d\.\d{4})};
  
  (defined($compra) or defined($venta)) ? return ($compra,$venta) : return (0,0);
  #return ($compra, $venta);
}#}}}
#{{{ signal and stuff
sub sayit {
  my ($server, $target, $msg) = @_;
  $server->command("MSG $target $msg");
}
signal_add("showme the money","do_dolar");
#}}}

#do a fetch when the script is loaded.
getPrice();
